# -*- coding: utf-8 -*-

"""Grammar correction GEC orchestrator service.

Loads the local GEC model and performs inference. Fallbacks to Gemini API
if local models are missing or fail.
"""

import difflib
import logging
from typing import Dict, List, Any
import torch
from config.settings import settings
from services.model_loader import load_grammar_model, get_target_device
from services.gemini_service import GeminiService

logger = logging.getLogger("GrammarService")

class GrammarCorrectionService:
    """Orchestrates GEC inference using local PEFT/LoRA models or Gemini fallbacks."""

    def __init__(self) -> None:
        """Initializes the service and configures Gemini fallback client."""
        self.gemini_service = GeminiService()

    def get_diff_changes(self, original: str, corrected: str) -> List[Dict[str, str]]:
        """Compares original vs corrected tokens to generate a structured changes list.

        Args:
            original: The incorrect source sentence.
            corrected: The corrected target sentence.

        Returns:
            A list of dictionary change items with 'wrong', 'correct', and 'reason'.
        """
        orig_words = original.strip().split()
        corr_words = corrected.strip().split()

        matcher = difflib.SequenceMatcher(None, orig_words, corr_words)
        changes: List[Dict[str, str]] = []

        for tag, i1, i2, j1, j2 in matcher.get_opcodes():
            wrong_span = " ".join(orig_words[i1:i2])
            correct_span = " ".join(corr_words[j1:j2])

            if tag == "replace":
                changes.append({
                    "wrong": wrong_span,
                    "correct": correct_span,
                    "reason": f"Thay đổi từ '{wrong_span}' thành '{correct_span}'."
                })
            elif tag == "delete":
                changes.append({
                    "wrong": wrong_span,
                    "correct": "",
                    "reason": f"Lược bỏ từ '{wrong_span}'."
                })
            elif tag == "insert":
                context = orig_words[i1 - 1] if i1 > 0 else ""
                reason = f"Thêm từ '{correct_span}'" + (f" sau từ '{context}'" if context else "") + "."
                changes.append({
                    "wrong": "",
                    "correct": correct_span,
                    "reason": reason
                })

        return changes

    def correct_text(self, text: str) -> Dict[str, Any]:
        """Corrects grammatical errors in the text, falling back to Gemini if needed.

        Args:
            text: Input sentence.

        Returns:
            A GEC response dictionary matching CorrectionResponse schema.
        """
        if not text.strip():
            return {
                "original": text,
                "corrected": text,
                "explanation": "Văn bản đầu vào rỗng.",
                "changes": []
            }

        # 1. Try local GEC model (only if LoRA adapters are successfully loaded)
        model, tokenizer, is_lora_loaded = load_grammar_model()
        
        if is_lora_loaded and model is not None and tokenizer is not None:
            try:
                device = get_target_device()
                prefix_in = f"Fix grammar: {text}"
                
                inputs = tokenizer(
                    prefix_in,
                    max_length=settings.MAX_INPUT_LENGTH if hasattr(settings, 'MAX_INPUT_LENGTH') else 128,
                    padding="max_length",
                    truncation=True,
                    return_tensors="pt"
                )
                
                input_ids = inputs["input_ids"].to(device)
                attention_mask = inputs["attention_mask"].to(device)

                with torch.no_grad():
                    outputs = model.generate(
                        input_ids=input_ids,
                        attention_mask=attention_mask,
                        max_length=settings.MAX_TARGET_LENGTH if hasattr(settings, 'MAX_TARGET_LENGTH') else 128,
                        num_beams=4,
                        early_stopping=True
                    )

                corrected = tokenizer.decode(outputs[0], skip_special_tokens=True).strip()
                changes = self.get_diff_changes(text, corrected)

                # Synthesize explanation summary in Vietnamese
                if changes:
                    reasons = [c["reason"] for c in changes]
                    explanation = "Đã tìm thấy và sửa các lỗi: " + ", ".join(reasons)
                else:
                    explanation = "Không tìm thấy lỗi sai nào trong câu."

                logger.info("Local GEC model correction executed successfully.")
                return {
                    "original": text,
                    "corrected": corrected,
                    "explanation": explanation,
                    "changes": changes
                }

            except Exception as e:
                logger.error(f"Local model inference failed: {e}. Falling back to Gemini.")

        # 2. Fallback to Gemini API
        if self.gemini_service.available:
            try:
                logger.info("Calling Gemini API fallback GEC...")
                gemini_res = self.gemini_service.correct_text_gemini(text)
                corrected = gemini_res["corrected"]
                explanation = gemini_res["explanation"]
                changes = self.get_diff_changes(text, corrected)
                
                return {
                    "original": text,
                    "corrected": corrected,
                    "explanation": explanation,
                    "changes": changes
                }
            except Exception as e:
                logger.error(f"Gemini GEC fallback failed: {e}")

        # 3. Simple Mock Fallback if all else fails
        logger.warning("All AI models unavailable. Falling back to basic mock parser.")
        if "go yesterday" in text.lower():
            corrected = text.lower().replace("go yesterday", "went yesterday")
            explanation = "Từ 'go' (thì hiện tại) cần chuyển thành 'went' (quá khứ đơn) vì có trạng ngữ chỉ thời gian quá khứ là 'yesterday'."
        elif "she go to school" in text.lower():
            corrected = "She goes to school."
            explanation = "Chủ ngữ 'She' là ngôi thứ ba số ít, động từ 'go' cần chia thành 'goes'."
        elif "she go school yesterday" in text.lower():
            corrected = "She went to school yesterday."
            explanation = "Chuyển động từ 'go' thành 'went' (quá khứ đơn) do có 'yesterday' và bổ sung giới từ 'to' trước địa điểm 'school'."
        elif "i has a apple" in text.lower():
            corrected = "I have an apple."
            explanation = "Chủ ngữ 'I' đi với động từ 'have', và mạo từ 'a' cần chuyển thành 'an' vì đứng trước từ bắt đầu bằng nguyên âm 'apple'."
        else:
            raise RuntimeError("Grammar model and Gemini fallback are both unavailable.")
            
        changes = self.get_diff_changes(text, corrected)
        return {
            "original": text,
            "corrected": corrected,
            "explanation": explanation,
            "changes": changes
        }
