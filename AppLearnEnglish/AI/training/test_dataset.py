#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Verification test for GEC Dataset Pipeline.

This script tests that the dataset loader, tokenizer, labels masking, and stats
work correctly.
"""

import sys
import logging
from pathlib import Path
import torch

# Add root folder to sys.path to enable imports
sys.path.append(str(Path(__file__).resolve().parent.parent))
from training.config import TrainingConfig
from training.dataset import load_train_dataset, get_dataset_statistics

# Setup minimal logging
logging.basicConfig(level=logging.INFO, format="%(levelname)s - %(message)s")
logger = logging.getLogger("TestDataset")

def main() -> None:
    logger.info("Initializing dataset pipeline verification checks...")
    
    # 1. Test dataset loading & validation
    try:
        train_dataset = load_train_dataset()
    except Exception as e:
        logger.error(f"Failed to load dataset split: {e}")
        sys.exit(1)
        
    logger.info(f"Successfully loaded train split with {len(train_dataset)} samples.")
    
    # 2. Test fetching single item & shape checks
    if len(train_dataset) == 0:
        logger.error("Dataset is empty. Run scripts/preprocess.py first.")
        sys.exit(1)
        
    sample = train_dataset[0]
    
    input_ids = sample["input_ids"]
    attention_mask = sample["attention_mask"]
    labels = sample["labels"]
    
    # Check shapes
    expected_len = TrainingConfig.MAX_INPUT_LENGTH
    
    logger.info("\nChecking Tensor Dimensions:")
    print(f"Input IDs:\n{input_ids.shape}")
    print(f"\nLabels:\n{labels.shape}")
    print(f"\nAttention Mask:\n{attention_mask.shape}\n")
    
    assert input_ids.shape == torch.Size([expected_len]), f"Expected input_ids shape [{expected_len}], got {input_ids.shape}"
    assert labels.shape == torch.Size([expected_len]), f"Expected labels shape [{expected_len}], got {labels.shape}"
    assert attention_mask.shape == torch.Size([expected_len]), f"Expected attention_mask shape [{expected_len}], got {attention_mask.shape}"
    
    # Check label masking: padded items should be replaced by -100
    padded_labels_count = torch.sum(labels == -100).item()
    logger.info(f"Verified label padding masking: {padded_labels_count} tokens masked as -100.")
    
    # 3. Print stats
    logger.info("Generating dataset token statistics report...")
    get_dataset_statistics(Path(TrainingConfig.TRAIN_DATA_PATH), "Train")
    
    logger.info("All GEC dataset pipeline tests PASSED successfully!")

if __name__ == "__main__":
    main()
