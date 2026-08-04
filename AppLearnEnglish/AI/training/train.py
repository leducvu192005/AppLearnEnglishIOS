# -*- coding: utf-8 -*-

"""Fine-tuning pipeline for GEC model using PEFT LoRA.

This script parses training args, loads datasets, wraps the seq2seq model
in a LoRA configuration, runs seq2seq training, and saves checkpoints.
"""

import os
import argparse
import logging
from pathlib import Path
import torch
from torch.utils.data import DataLoader
from transformers import (
    AutoModelForSeq2SeqLM,
    AutoTokenizer,
    Seq2SeqTrainer,
    Seq2SeqTrainingArguments,
    DataCollatorForSeq2Seq
)
from peft import LoraConfig, get_peft_model, TaskType

import sys
sys.path.append(str(Path(__file__).resolve().parent.parent))

# Imports from training files
from training.config import TrainingConfig
from training.lora_config import LoraConfigParams
from training.trainer_config import TrainerConfigParams
from training.dataset import load_train_dataset, load_validation_dataset
from training.utils import set_seed, get_device, save_config, model_summary

logger = logging.getLogger("TrainPipeline")

def main() -> None:
    """Orchestrates GEC model fine-tuning with PEFT LoRA."""
    parser = argparse.ArgumentParser(description="Fine-tune FLAN-T5 GEC model using LoRA")
    parser.add_argument(
        "--test-run",
        action="store_true",
        help="Loads model/dataset, passes one batch, and exits without full training"
    )
    parser.add_argument(
        "--resume",
        type=str,
        default=None,
        help="Checkpoint directory name (e.g. checkpoint-500) to resume training from"
    )
    args = parser.parse_args()

    # 1. Initialize environment & seed
    set_seed(TrainerConfigParams.SEED)
    device = get_device()

    # Create output checkpoints directory
    output_dir = Path(TrainerConfigParams.OUTPUT_DIR)
    output_dir.mkdir(parents=True, exist_ok=True)

    # 2. Initialize tokenizer and model
    logger.info(f"Loading tokenizer: {TrainerConfigParams.MODEL_NAME}...")
    tokenizer = AutoTokenizer.from_pretrained(TrainerConfigParams.MODEL_NAME)

    logger.info(f"Loading base Seq2Seq model: {TrainerConfigParams.MODEL_NAME}...")
    model = AutoModelForSeq2SeqLM.from_pretrained(TrainerConfigParams.MODEL_NAME)
    
    # 3. Apply PEFT/LoRA wrapper
    logger.info("Applying LoRA Adapter...")
    peft_config = LoraConfig(
        r=LoraConfigParams.LORA_R,
        lora_alpha=LoraConfigParams.LORA_ALPHA,
        target_modules=LoraConfigParams.TARGET_MODULES,
        lora_dropout=LoraConfigParams.LORA_DROPOUT,
        bias="none",
        task_type=TaskType.SEQ_2_SEQ_LM
    )
    model = get_peft_model(model, peft_config)
    model_summary(model)

    # Move model to resolved device
    model.to(device)

    # 4. Load datasets
    logger.info("Loading GEC datasets splits...")
    train_dataset = load_train_dataset(tokenizer)
    val_dataset = load_validation_dataset(tokenizer)

    # 5. Handle Test Run Option
    if args.test_run:
        logger.info("Starting verification test run (Forward Pass Check)...")
        # Collator
        data_collator = DataCollatorForSeq2Seq(tokenizer, model=model, padding="max_length", max_length=TrainerConfigParams.MAX_INPUT_LENGTH)
        test_loader = DataLoader(train_dataset, batch_size=2, shuffle=True, collate_fn=data_collator)
        
        batch = next(iter(test_loader))
        
        # Load item batch to target device
        input_ids = batch["input_ids"].to(device)
        attention_mask = batch["attention_mask"].to(device)
        labels = batch["labels"].to(device)

        model.eval()
        with torch.no_grad():
            outputs = model(
                input_ids=input_ids,
                attention_mask=attention_mask,
                labels=labels
            )
        
        logger.info(f"Forward pass completed successfully. Loss: {outputs.loss.item():.4f}")
        logger.info("Verification check PASSED. Exiting without training.")
        return

    # 6. Full Sequence-to-Sequence Training
    logger.info("Configuring Seq2SeqTrainingArguments...")
    
    # Hugging Face Seq2Seq Training args
    training_args = Seq2SeqTrainingArguments(
        output_dir=TrainerConfigParams.OUTPUT_DIR,
        per_device_train_batch_size=TrainerConfigParams.BATCH_SIZE,
        per_device_eval_batch_size=TrainerConfigParams.BATCH_SIZE,
        gradient_accumulation_steps=TrainerConfigParams.GRADIENT_ACCUMULATION_STEPS,
        learning_rate=TrainerConfigParams.LEARNING_RATE,
        num_train_epochs=TrainerConfigParams.NUM_EPOCHS,
        evaluation_strategy="epoch",
        save_strategy="epoch",
        logging_steps=10,
        save_total_limit=2,
        predict_with_generate=True,
        use_cpu=True if device.type == "cpu" else False,
        seed=TrainerConfigParams.SEED,
        report_to="none"
    )

    data_collator = DataCollatorForSeq2Seq(
        tokenizer,
        model=model,
        label_pad_token_id=-100,
        pad_to_multiple_of=8
    )

    trainer = Seq2SeqTrainer(
        model=model,
        args=training_args,
        train_dataset=train_dataset,
        eval_dataset=val_dataset,
        tokenizer=tokenizer,
        data_collator=data_collator
    )

    # Check for resume checkpoint
    resume_checkpoint_dir = None
    if args.resume:
        resume_checkpoint_dir = str(output_dir / args.resume)
        if not os.path.exists(resume_checkpoint_dir):
            logger.error(f"Resume checkpoint directory does not exist: {resume_checkpoint_dir}")
            raise FileNotFoundError(f"Resume checkpoint not found: {resume_checkpoint_dir}")
        logger.info(f"Resuming training from checkpoint: {resume_checkpoint_dir}")

    logger.info("Starting Seq2Seq training sequence...")
    trainer.train(resume_from_checkpoint=resume_checkpoint_dir)

    # Save final model & configurations
    final_output_path = output_dir / "checkpoint-final"
    logger.info(f"Saving final adapter model to: {final_output_path}")
    trainer.save_model(str(final_output_path))
    
    # Save training parameters for provenance
    config_dict = {
        "model_name": TrainerConfigParams.MODEL_NAME,
        "lora_r": LoraConfigParams.LORA_R,
        "lora_alpha": LoraConfigParams.LORA_ALPHA,
        "lora_dropout": LoraConfigParams.LORA_DROPOUT,
        "learning_rate": TrainerConfigParams.LEARNING_RATE,
        "epochs": TrainerConfigParams.NUM_EPOCHS,
        "batch_size": TrainerConfigParams.BATCH_SIZE
    }
    save_config(config_dict, final_output_path / "trainer_config.json")
    logger.info("Fine-tuning pipeline executed successfully.")

if __name__ == "__main__":
    # Setup execution logging
    logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
    main()
