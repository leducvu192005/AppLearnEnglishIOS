# -*- coding: utf-8 -*-

"""Evaluation pipeline for GEC model testing.

Loads the fine-tuned LoRA model (or falls back to base model), runs predictions
on the test split, calculates GEC performance metrics, and saves logs.
"""

import sys
import json
import logging
from pathlib import Path
from typing import Dict, List, Any
import torch
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
from peft import PeftModel

# Add parent and local path to import training configs, utils and local metrics modules
sys.path.append(str(Path(__file__).resolve().parent.parent))
sys.path.append(str(Path(__file__).resolve().parent))

from training.config import TrainingConfig
from training.dataset import validate_jsonl_file
from training.utils import get_device

from metrics import calculate_bleu, calculate_gleu, calculate_exact_match, calculate_wer
from error_analysis import analyze_prediction_error

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(levelname)s - %(message)s")
logger = logging.getLogger("GECEvaluation")

# MARK: - Load Model Helper

def load_gec_model(checkpoint_dir: Path, device: torch.device) -> Any:
    """Loads the base FLAN-T5 model wrapped with LoRA adapters if present.

    Args:
        checkpoint_dir: Path to the fine-tuned checkpoint folder.
        device: Computational device.

    Returns:
        The loaded PyTorch model.
    """
    base_model_name = TrainingConfig.MODEL_NAME
    logger.info(f"Loading tokenizer: {base_model_name}")
    tokenizer = AutoTokenizer.from_pretrained(base_model_name)

    logger.info(f"Loading base Seq2Seq model: {base_model_name}")
    model = AutoModelForSeq2SeqLM.from_pretrained(base_model_name)

    # Check for LoRA adapters
    adapter_path = checkpoint_dir / "adapter_config.json"
    if checkpoint_dir.exists() and adapter_path.exists():
        logger.info(f"Loading LoRA adapters from: {checkpoint_dir}")
        model = PeftModel.from_pretrained(model, str(checkpoint_dir))
    else:
        logger.warning(
            f"No LoRA adapter found at '{checkpoint_dir}'. "
            "Falling back to BASE model evaluation only."
        )

    model.to(device)
    model.eval()
    return model, tokenizer

# MARK: - Inference Helper

def generate_correction(sentence: str, model: Any, tokenizer: Any, device: torch.device) -> str:
    """Generates grammar correction for a single raw input sentence.

    Args:
        sentence: The raw input sentence (with or without prefix).
        model: Loaded PyTorch model.
        tokenizer: Loaded Hugging Face tokenizer.
        device: Computational device.

    Returns:
        The corrected sentence.
    """
    # Ensure prefix is present
    if not sentence.startswith("Fix grammar:"):
        sentence = f"Fix grammar: {sentence}"

    inputs = tokenizer(
        sentence,
        max_length=TrainingConfig.MAX_INPUT_LENGTH,
        padding="max_length",
        truncation=True,
        return_tensors="pt"
    )
    
    input_ids = inputs["input_ids"].to(device)
    attention_mask = inputs["attention_mask"].to(device)

    with torch.no_grad():
        outputs = model.generate(
            input_ids=input_ids,
            attention_mask=attention_mask,
            max_length=TrainingConfig.MAX_TARGET_LENGTH,
            num_beams=4,
            early_stopping=True
        )

    corrected = tokenizer.decode(outputs[0], skip_special_tokens=True)
    return corrected

# MARK: - Model Comparison

def compare_models(test_sentences: List[str], checkpoint_dir: Path, device: torch.device) -> None:
    """Compares correction outputs of base model vs fine-tuned LoRA model side-by-side.

    Args:
        test_sentences: List of raw incorrect sentences.
        checkpoint_dir: LoRA adapters folder path.
        device: Computational device.
    """
    logger.info("\n=== Running Model Comparison (Base vs. Fine-tuned) ===")
    
    # Load base model only
    base_model = AutoModelForSeq2SeqLM.from_pretrained(TrainingConfig.MODEL_NAME).to(device)
    tokenizer = AutoTokenizer.from_pretrained(TrainingConfig.MODEL_NAME)
    base_model.eval()

    # Load fine-tuned model (base + LoRA)
    ft_model, _ = load_gec_model(checkpoint_dir, device)

    for idx, sent in enumerate(test_sentences, 1):
        # Generate base correction
        base_corrected = generate_correction(sent, base_model, tokenizer, device)
        # Generate fine-tuned correction
        ft_corrected = generate_correction(sent, ft_model, tokenizer, device)

        print(f"\n{idx}. Original:   {sent}")
        print(f"   Base Model: {base_corrected}")
        print(f"   Fine-tuned: {ft_corrected}")
    print("\n=======================================================\n")

# MARK: - Main Evaluation Function

def evaluate_model(limit: int = 100) -> None:
    """Runs evaluation over test dataset split and writes statistics reports.

    Args:
        limit: Max samples to evaluate (keeps evaluations fast).
    """
    device = get_device()
    checkpoint_dir = Path(TrainingConfig.CHECKPOINT_DIR) / "checkpoint-final"
    test_file_path = Path(TrainingConfig.TEST_DATA_PATH)

    # 1. Load model and tokenizer
    model, tokenizer = load_gec_model(checkpoint_dir, device)

    # 2. Read test samples
    logger.info(f"Loading GEC test split from: {test_file_path}")
    samples = validate_jsonl_file(test_file_path)
    
    if limit > 0:
        samples = samples[:limit]
    logger.info(f"Evaluating {len(samples)} test samples...")

    # Lists for metric computations
    bleu_scores: List[float] = []
    gleu_scores: List[float] = []
    em_scores: List[float] = []
    wer_scores: List[float] = []
    
    error_cases: List[Dict[str, str]] = []

    # 3. Generate corrections & analyze
    for idx, sample in enumerate(samples, 1):
        raw_in = sample["input"]
        raw_target = sample["target"]
        source_name = sample["source"]

        # Predict correction
        prediction = generate_correction(raw_in, model, tokenizer, device)

        # Calculate metrics
        bleu = calculate_bleu(prediction, raw_target)
        gleu = calculate_gleu(raw_in, prediction, raw_target)
        em = calculate_exact_match(prediction, raw_target)
        wer = calculate_wer(prediction, raw_target)

        bleu_scores.append(bleu)
        gleu_scores.append(gleu)
        em_scores.append(em)
        wer_scores.append(wer)

        # Error analysis
        err_type = analyze_prediction_error(raw_in, prediction, raw_target)
        if err_type != "correct":
            error_cases.append({
                "input": raw_in.replace("Fix grammar: ", ""),
                "prediction": prediction,
                "target": raw_target,
                "error_type": err_type
            })

    # Average metrics
    avg_bleu = sum(bleu_scores) / len(bleu_scores) if bleu_scores else 0.0
    avg_gleu = sum(gleu_scores) / len(gleu_scores) if gleu_scores else 0.0
    avg_em = sum(em_scores) / len(em_scores) if em_scores else 0.0
    avg_wer = sum(wer_scores) / len(wer_scores) if wer_scores else 0.0

    # 4. Generate report files
    reports_dir = Path(__file__).resolve().parent / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)

    report_txt_path = reports_dir / "evaluation_report.txt"
    error_cases_json_path = reports_dir / "error_cases.json"

    # Save report.txt
    with open(report_txt_path, "w", encoding="utf-8") as f:
        f.write("=================================\n")
        f.write("Grammar Correction Evaluation\n")
        f.write("=================================\n\n")
        f.write(f"Model:\nFLAN-T5 Base + LoRA (Adapters: {checkpoint_dir.exists()})\n\n")
        f.write(f"Dataset:\n{test_file_path.name}\n\n")
        f.write(f"Samples:\n{len(samples)}\n\n")
        f.write(f"BLEU:\n{avg_bleu:.4f}\n\n")
        f.write(f"GLEU:\n{avg_gleu:.4f}\n\n")
        f.write(f"Exact Match:\n{avg_em:.4f}\n\n")
        f.write(f"WER:\n{avg_wer:.4f}\n")
        f.write("\n=================================\n")

    # Save error cases JSON
    with open(error_cases_json_path, "w", encoding="utf-8") as f:
        json.dump(error_cases, f, indent=4, ensure_ascii=False)

    logger.info(f"Saved evaluation report to: {report_txt_path}")
    logger.info(f"Saved error analysis cases to: {error_cases_json_path}")

    # Print summary metrics to console
    print("\n=================================")
    print("Grammar Correction Evaluation Summary")
    print(f"BLEU Score:       {avg_bleu:.4f}")
    print(f"GLEU Score:       {avg_gleu:.4f}")
    print(f"Exact Match:      {avg_em:.4f}")
    print(f"Word Error Rate:  {avg_wer:.4f}")
    print("=================================\n")

if __name__ == "__main__":
    # If run as CLI, perform evaluation on 50 samples
    evaluate_model(limit=50)
