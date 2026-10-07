#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""config.py
Configuration variables, hyperparameters, model paths, and settings
for fine-tuning FLAN-T5 GEC model using LoRA.
"""

from pathlib import Path

class TrainingConfig:
    # Model parameters
    MODEL_NAME = "google/flan-t5-base"
    RANDOM_SEED = 42
    
    # Sequence lengths
    MAX_INPUT_LENGTH = 128
    MAX_TARGET_LENGTH = 128
    
    # LoRA parameters
    LORA_R = 8
    LORA_ALPHA = 32
    LORA_DROPOUT = 0.05
    LORA_TARGET_MODULES = ["q", "v"]
    
    # Hyperparameters
    BATCH_SIZE = 8
    LEARNING_RATE = 3e-4
    NUM_EPOCHS = 3
    WARMUP_RATIO = 0.03
    
    # Paths
    AI_ROOT = Path(__file__).resolve().parent.parent
    TRAIN_DATA_PATH = str(AI_ROOT / "datasets" / "processed" / "train.jsonl")
    VAL_DATA_PATH = str(AI_ROOT / "datasets" / "processed" / "validation.jsonl")
    TEST_DATA_PATH = str(AI_ROOT / "datasets" / "processed" / "test.jsonl")
    CHECKPOINT_DIR = str(AI_ROOT / "checkpoints")
    EXPORT_DIR = str(AI_ROOT / "exports")

