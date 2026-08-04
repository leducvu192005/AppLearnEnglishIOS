# -*- coding: utf-8 -*-

"""Utility helpers for GEC model fine-tuning.

Includes device resolution (mps/cpu), reproducibility seeding,
config serialization, and model param summary reports.
"""

import json
import random
import logging
from pathlib import Path
from typing import Any, Dict
import numpy as np
import torch

logger = logging.getLogger("TrainingUtils")

def set_seed(seed: int = 42) -> None:
    """Sets random seed across python, numpy, and PyTorch for reproducibility.

    Args:
        seed: The integer seed value.
    """
    random.seed(seed)
    np.random.seed(seed)
    torch.manual_seed(seed)
    if torch.cuda.is_available():
        torch.cuda.manual_seed_all(seed)
    logger.info(f"Random seed set to: {seed}")

def get_device() -> torch.device:
    """Resolves computational device to MPS (Apple Silicon), CUDA, or CPU.

    Returns:
        A torch.device instance.
    """
    if torch.backends.mps.is_available():
        logger.info("Apple Silicon GPU (MPS) is available. Using 'mps'.")
        return torch.device("mps")
    elif torch.cuda.is_available():
        logger.info("NVIDIA CUDA GPU is available. Using 'cuda'.")
        return torch.device("cuda")
    else:
        logger.info("No accelerators found. Defaulting to 'cpu'.")
        return torch.device("cpu")

def save_config(config_dict: Dict[str, Any], output_path: Path) -> None:
    """Serializes configurations to a JSON file.

    Args:
        config_dict: Dictionary of configuration parameters.
        output_path: Target Path to save JSON.
    """
    try:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(config_dict, f, indent=4, ensure_ascii=False)
        logger.info(f"Saved configurations to: {output_path}")
    except Exception as e:
        logger.error(f"Failed saving configuration to {output_path}: {e}")

def model_summary(model: Any) -> None:
    """Prints total parameters, trainable parameters, and trainable ratio percentage.

    Args:
        model: The PyTorch or PEFT model.
    """
    total_params = sum(p.numel() for p in model.parameters())
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
    trainable_pct = (trainable_params / total_params * 100) if total_params > 0 else 0.0

    print("\n================================================")
    print("Model Parameters")
    print(f"Total parameters:      {total_params:,}")
    print(f"Trainable parameters:  {trainable_params:,}")
    print(f"Trainable percentage:  {trainable_pct:.4f}%")
    print("================================================\n")
