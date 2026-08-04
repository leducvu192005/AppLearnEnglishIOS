# -*- coding: utf-8 -*-

"""Model loader service for caching models in RAM.

Handles loading base models and LoRA adapters on startup.
"""

import os
import logging
from pathlib import Path
from typing import Tuple, Any, Optional
import torch
from transformers import AutoModelForSeq2SeqLM, AutoTokenizer
from peft import PeftModel
from config.settings import settings

logger = logging.getLogger("ModelLoader")

# Global in-memory caches
_cached_model: Optional[Any] = None
_cached_tokenizer: Optional[Any] = None
_cached_is_lora: bool = False

def get_target_device() -> torch.device:
    """Resolves computational device based on settings configuration and availability.

    Returns:
        torch.device instance.
    """
    requested_device = settings.DEVICE.lower()
    if requested_device == "mps" and torch.backends.mps.is_available():
        return torch.device("mps")
    elif requested_device == "cuda" and torch.cuda.is_available():
        return torch.device("cuda")
    return torch.device("cpu")

def load_grammar_model() -> Tuple[Optional[Any], Optional[Any], bool]:
    """Loads base FLAN-T5 model and overlays LoRA adapter. Caches them in RAM.

    Returns:
        Tuple of (model, tokenizer, is_lora_loaded) or (None, None, False) if loading fails.
    """
    global _cached_model, _cached_tokenizer, _cached_is_lora

    # Return cached instances if already loaded
    if _cached_model is not None and _cached_tokenizer is not None:
        return _cached_model, _cached_tokenizer, _cached_is_lora

    device = get_target_device()
    base_model_name = settings.BASE_MODEL
    adapter_path = Path(settings.MODEL_PATH)

    logger.info(f"Resolving model target device: {device}")

    try:
        logger.info(f"Loading tokenizer: {base_model_name}")
        tokenizer = AutoTokenizer.from_pretrained(base_model_name)

        logger.info(f"Loading base Seq2Seq model: {base_model_name}")
        model = AutoModelForSeq2SeqLM.from_pretrained(base_model_name)

        is_lora = False
        # Check if local adapter exists
        if adapter_path.exists() and (adapter_path / "adapter_config.json").exists():
            logger.info(f"Loading PEFT/LoRA adapter from: {adapter_path}")
            model = PeftModel.from_pretrained(model, str(adapter_path))
            is_lora = True
        else:
            logger.warning(
                f"LoRA adapter config not found at: {adapter_path}. "
                "Base FLAN-T5 model loaded but GEC LoRA features remain inactive."
            )

        model.to(device)
        model.eval()

        # Cache in memory
        _cached_model = model
        _cached_tokenizer = tokenizer
        _cached_is_lora = is_lora
        logger.info(f"Successfully loaded local GEC model (LoRA loaded: {is_lora}) in RAM.")
        return _cached_model, _cached_tokenizer, _cached_is_lora

    except Exception as e:
        logger.error(f"Failed loading local GEC model: {e}. Fallback to Gemini will be active.")
        return None, None, False
