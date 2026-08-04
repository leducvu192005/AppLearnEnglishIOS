#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Interactive GEC Model Inference CLI.

Enables developers or users to check corrections dynamically via terminal prompts
using the loaded PEFT adapter checkpoints.
"""

import sys
import logging
from pathlib import Path
import torch

# Add parent and local path to import training configs, utils and evaluation modules
sys.path.append(str(Path(__file__).resolve().parent.parent))
sys.path.append(str(Path(__file__).resolve().parent))
from training.config import TrainingConfig
from training.utils import get_device
from evaluate import load_gec_model, generate_correction

# Configure minimal console logs
logging.basicConfig(level=logging.WARNING, format="%(levelname)s - %(message)s")

def interactive_cli() -> None:
    """Runs interactive loop reading user inputs and outputting model grammar corrections."""
    device = get_device()
    checkpoint_dir = Path(TrainingConfig.CHECKPOINT_DIR) / "checkpoint-final"
    
    print("\nLoading GEC Model for interactive inference...")
    try:
        model, tokenizer = load_gec_model(checkpoint_dir, device)
    except Exception as e:
        print(f"Failed to load model: {e}")
        sys.exit(1)
        
    print("\nGEC Model Loaded successfully!")
    print("Type your incorrect sentences below to receive corrections.")
    print("Type 'exit' or 'quit' to close the interface.\n")
    print("-" * 50)

    try:
        while True:
            # Python standard prompt input
            try:
                user_input = input("Enter sentence: ").strip()
            except (KeyboardInterrupt, EOFError):
                print("\nExiting interactive CLI...")
                break
                
            if not user_input:
                continue
                
            if user_input.lower() in ["exit", "quit"]:
                print("Goodbye!")
                break
                
            # Perform correction inference
            try:
                corrected = generate_correction(user_input, model, tokenizer, device)
                print(f"Correction:     {corrected}\n")
            except Exception as ex:
                print(f"Error during model generation: {ex}\n")
            print("-" * 50)
    except Exception as general_error:
        print(f"An unexpected CLI error occurred: {general_error}")

if __name__ == "__main__":
    interactive_cli()
