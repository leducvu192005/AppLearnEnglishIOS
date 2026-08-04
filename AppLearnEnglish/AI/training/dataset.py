# -*- coding: utf-8 -*-

"""PyTorch Dataset & Tokenization Pipeline for GEC Model Fine-Tuning.

This module implements the GrammarCorrectionDataset class, helpers to load
train/val/test splits, and tools to audit dataset token statistics.
"""

import json
import logging
from pathlib import Path
from typing import Dict, List, Any, Optional
import torch
from torch.utils.data import Dataset
from transformers import AutoTokenizer
from training.config import TrainingConfig

logger = logging.getLogger("DatasetPipeline")

# MARK: - Data Validation Helper

def validate_jsonl_file(file_path: Path) -> List[Dict[str, str]]:
    """Reads a GEC JSON Lines file and validates that each sample contains correct keys.

    Args:
        file_path: Path to the JSONL dataset.

    Returns:
        A list of verified dictionary samples.
    """
    valid_samples: List[Dict[str, str]] = []
    
    if not file_path.exists():
        logger.error(f"Dataset file does not exist: {file_path}")
        raise FileNotFoundError(f"Dataset file not found: {file_path}")
        
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            for idx, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue
                try:
                    data = json.loads(line)
                    # Check keys
                    if "input" not in data or "target" not in data or "source" not in data:
                        logger.warning(
                            f"Malformed keys at line {idx} in {file_path.name}. "
                            f"Keys must include 'input', 'target', and 'source'."
                        )
                        continue
                    
                    # Check non-empty values
                    if not str(data["input"]).strip() or not str(data["target"]).strip():
                        logger.warning(f"Empty value at line {idx} in {file_path.name}.")
                        continue
                        
                    valid_samples.append({
                        "input": str(data["input"]),
                        "target": str(data["target"]),
                        "source": str(data["source"])
                    })
                except json.JSONDecodeError as je:
                    logger.error(f"JSON decode failure at line {idx} in {file_path.name}: {je}")
                    continue
    except Exception as e:
        logger.error(f"Failed to read dataset file {file_path}: {e}")
        raise
        
    return valid_samples

# MARK: - PyTorch Dataset Class

class GrammarCorrectionDataset(Dataset):
    """PyTorch Dataset wrapper for GEC tokenization inputs & masked labels."""

    def __init__(
        self,
        samples: List[Dict[str, str]],
        tokenizer: AutoTokenizer,
        max_input_len: int = TrainingConfig.MAX_INPUT_LENGTH,
        max_target_len: int = TrainingConfig.MAX_TARGET_LENGTH
    ) -> None:
        """Initializes the dataset with samples, tokenizer, and length limits.

        Args:
            samples: List of validated dictionary samples.
            tokenizer: Hugging Face tokenizer instance.
            max_input_len: Maximum token length for the source inputs.
            max_target_len: Maximum token length for the target labels.
        """
        self.samples = samples
        self.tokenizer = tokenizer
        self.max_input_len = max_input_len
        self.max_target_len = max_target_len

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, idx: int) -> Dict[str, torch.Tensor]:
        """Tokenizes a sample and prepares input_ids, attention_mask, and masked labels.

        Args:
            idx: The integer index of the sample.

        Returns:
            A dictionary containing input_ids, attention_mask, and labels tensors.
        """
        sample = self.samples[idx]
        input_text = sample["input"]
        target_text = sample["target"]

        # Tokenize input sentence
        input_encoding = self.tokenizer(
            input_text,
            max_length=self.max_input_len,
            padding="max_length",
            truncation=True,
            return_tensors="pt"
        )

        # Tokenize target corrected sentence
        target_encoding = self.tokenizer(
            target_text,
            max_length=self.max_target_len,
            padding="max_length",
            truncation=True,
            return_tensors="pt"
        )

        input_ids = input_encoding["input_ids"].squeeze(0)
        attention_mask = input_encoding["attention_mask"].squeeze(0)
        labels = target_encoding["input_ids"].squeeze(0)

        # Replace padding token ids in labels with -100 so that PyTorch
        # CrossEntropyLoss ignores them during loss computation.
        labels[labels == self.tokenizer.pad_token_id] = -100

        return {
            "input_ids": input_ids,
            "attention_mask": attention_mask,
            "labels": labels
        }

# MARK: - Dataset Loading Helpers

def load_train_dataset(tokenizer: Optional[AutoTokenizer] = None) -> GrammarCorrectionDataset:
    """Loads the tokenized training dataset split.

    Args:
        tokenizer: Optional tokenizer instance. Creates new one if None.

    Returns:
        An instance of GrammarCorrectionDataset.
    """
    if tokenizer is None:
        tokenizer = AutoTokenizer.from_pretrained(TrainingConfig.MODEL_NAME)
    samples = validate_jsonl_file(Path(TrainingConfig.TRAIN_DATA_PATH))
    return GrammarCorrectionDataset(samples, tokenizer)

def load_validation_dataset(tokenizer: Optional[AutoTokenizer] = None) -> GrammarCorrectionDataset:
    """Loads the tokenized validation dataset split.

    Args:
        tokenizer: Optional tokenizer instance. Creates new one if None.

    Returns:
        An instance of GrammarCorrectionDataset.
    """
    if tokenizer is None:
        tokenizer = AutoTokenizer.from_pretrained(TrainingConfig.MODEL_NAME)
    samples = validate_jsonl_file(Path(TrainingConfig.VAL_DATA_PATH))
    return GrammarCorrectionDataset(samples, tokenizer)

def load_test_dataset(tokenizer: Optional[AutoTokenizer] = None) -> GrammarCorrectionDataset:
    """Loads the tokenized test dataset split.

    Args:
        tokenizer: Optional tokenizer instance. Creates new one if None.

    Returns:
        An instance of GrammarCorrectionDataset.
    """
    if tokenizer is None:
        tokenizer = AutoTokenizer.from_pretrained(TrainingConfig.MODEL_NAME)
    samples = validate_jsonl_file(Path(TrainingConfig.TEST_DATA_PATH))
    return GrammarCorrectionDataset(samples, tokenizer)

# MARK: - Dataset Statistics Auditing

def get_dataset_statistics(file_path: Path, split_name: str) -> None:
    """Computes and logs token distribution statistics for a given split file.

    Args:
        file_path: Path to the JSONL dataset split.
        split_name: Name label of the split (e.g. 'Train', 'Validation').
    """
    samples = validate_jsonl_file(file_path)
    tokenizer = AutoTokenizer.from_pretrained(TrainingConfig.MODEL_NAME)
    
    input_lens: List[int] = []
    target_lens: List[int] = []
    
    for sample in samples:
        input_tokens = tokenizer.encode(sample["input"])
        target_tokens = tokenizer.encode(sample["target"])
        input_lens.append(len(input_tokens))
        target_lens.append(len(target_tokens))
        
    avg_in = sum(input_lens) / len(input_lens) if input_lens else 0
    avg_tgt = sum(target_lens) / len(target_lens) if target_lens else 0
    max_in = max(input_lens) if input_lens else 0
    min_in = min(input_lens) if input_lens else 0
    
    print(f"\n============================")
    print(f"{split_name} Dataset")
    print(f"Samples: {len(samples)}")
    print(f"Average Input Tokens: {int(avg_in)}")
    print(f"Average Target Tokens: {int(avg_tgt)}")
    print(f"Max Input Tokens: {max_in}")
    print(f"Min Input Tokens: {min_in}")
    print(f"============================\n")
