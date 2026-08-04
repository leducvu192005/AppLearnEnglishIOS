# -*- coding: utf-8 -*-

"""LoRA PEFT hyperparameters for fine-tuning GEC model.

This configuration specifies parameters for low-rank adapters tailored
to the T5 model architecture.
"""

from typing import List

class LoraConfigParams:
    """LoRA parameter registry."""
    # Rank of the low-rank adaptation matrix (smaller rank avoids out-of-memory)
    LORA_R: int = 8
    
    # Scaling factor for the adapter parameters
    LORA_ALPHA: int = 32
    
    # Dropout probability for LoRA layers to prevent overfitting
    LORA_DROPOUT: float = 0.05
    
    # Attention layers targeted for LoRA insertion in the T5 architecture
    TARGET_MODULES: List[str] = ["q", "v"]
