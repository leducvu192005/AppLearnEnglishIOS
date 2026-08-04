# -*- coding: utf-8 -*-

"""Training configurations for Seq2SeqTrainer.

Consolidates epoch, learning rate, and memory-saving configurations
tuned for Apple Silicon hardware.
"""

import os
from pathlib import Path

class TrainerConfigParams:
    """Trainer configuration settings."""
    # Model base name
    MODEL_NAME: str = "google/flan-t5-base"
    
    # Directory to store training checkpoints
    OUTPUT_DIR: str = str(Path(__file__).resolve().parent.parent / "checkpoints")
    
    # Hyperparameters
    NUM_EPOCHS: int = 3
    LEARNING_RATE: float = 3e-4
    BATCH_SIZE: int = 4
    GRADIENT_ACCUMULATION_STEPS: int = 2
    
    # Token limits
    MAX_INPUT_LENGTH: int = 128
    MAX_TARGET_LENGTH: int = 128
    
    # Replicability seed
    SEED: int = 42
