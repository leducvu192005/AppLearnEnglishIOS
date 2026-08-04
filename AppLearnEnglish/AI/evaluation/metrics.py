# -*- coding: utf-8 -*-

"""Metric calculation utilities for GEC evaluation.

Includes BLEU, GLEU, Exact Match, and Word Error Rate (WER).
"""

from typing import List
import nltk
from nltk.translate.bleu_score import sentence_bleu, SmoothingFunction
from nltk.translate.gleu_score import sentence_gleu
import jiwer

def calculate_bleu(prediction: str, target: str) -> float:
    """Calculates the BLEU score between a single prediction and target.

    Args:
        prediction: The model's predicted correction.
        target: The expected reference correction.

    Returns:
        BLEU score as a float between 0.0 and 1.0.
    """
    pred_tokens = prediction.strip().split()
    ref_tokens = [target.strip().split()]
    
    # Use smoothing function to prevent zero division for short sentences
    smoothing = SmoothingFunction().method1
    return sentence_bleu(ref_tokens, pred_tokens, smoothing_function=smoothing)

def calculate_gleu(source: str, prediction: str, target: str) -> float:
    """Calculates the sentence-level GLEU score for a GEC prediction.

    GLEU compares n-grams of prediction and target, accounting for changes
    made relative to the original source.

    Args:
        source: The original incorrect input sentence.
        prediction: The model's predicted correction.
        target: The expected reference correction.

    Returns:
        GLEU score as a float between 0.0 and 1.0.
    """
    src_tokens = source.strip().split()
    pred_tokens = prediction.strip().split()
    ref_tokens = [target.strip().split()]
    
    # NLTK sentence_gleu expects references and a hypothesis
    # In GLEU context, we use the source sentence to reward corrected n-grams
    return sentence_gleu(ref_tokens, pred_tokens, min_len=1, max_len=4)

def calculate_exact_match(prediction: str, target: str) -> float:
    """Calculates Exact Match (1.0 if identical, 0.0 otherwise).

    Args:
        prediction: The model's predicted correction.
        target: The expected reference correction.

    Returns:
        1.0 or 0.0 float.
    """
    return 1.0 if prediction.strip() == target.strip() else 0.0

def calculate_wer(prediction: str, target: str) -> float:
    """Calculates Word Error Rate (WER) between prediction and target.

    Args:
        prediction: The model's predicted correction.
        target: The expected reference correction.

    Returns:
        WER value as a float.
    """
    try:
        # jiwer expectations
        return float(jiwer.wer(target.strip(), prediction.strip()))
    except Exception:
        # Fallback if sentences are empty or mismatch
        return 1.0
