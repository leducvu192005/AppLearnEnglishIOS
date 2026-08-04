# -*- coding: utf-8 -*-

"""Error Analysis helper for GEC predictions.

Categorizes GEC prediction errors into missed corrections, wrong corrections,
or over-corrections.
"""

from typing import Dict, Any

def analyze_prediction_error(input_text: str, prediction: str, target: str) -> str:
    """Categorizes model GEC correction output into distinct error categories.

    Args:
        input_text: The source sentence (with or without 'Fix grammar: ' prefix).
        prediction: The predicted correct sentence from the model.
        target: The reference correct target sentence.

    Returns:
        One of: 'correct', 'missed_correction', 'wrong_correction', 'over_correction'.
    """
    raw_in = input_text.replace("Fix grammar: ", "").strip()
    pred = prediction.strip()
    tgt = target.strip()
    
    if pred == tgt:
        return "correct"
        
    if raw_in != tgt:
        # Input was incorrect, but model made no changes
        if pred == raw_in:
            return "missed_correction"
        # Input was incorrect, model made changes, but did not match target reference
        else:
            return "wrong_correction"
    else:
        # Input was already correct, but model modified it
        return "over_correction"
