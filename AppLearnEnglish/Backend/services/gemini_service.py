# -*- coding: utf-8 -*-

"""Gemini API GEC Fallback Service with RAG integration.

Interacts with the Google Gemini API to perform GEC and explanation generation,
augmented with a local grammar rules vector database.
"""

import json
import logging
import google.generativeai as genai
from config.settings import settings
from services.vector_db_service import VectorDBService

logger = logging.getLogger("GeminiService")

class GeminiService:
    """Encapsulates Google Gemini AI operations for GEC tasks with RAG support."""

    def __init__(self) -> None:
        """Initializes and configures the Gemini generative model and vector DB."""
        self.api_key = settings.GEMINI_API_KEY
        self.available = False
        self.vector_db = VectorDBService()

        if self.api_key:
            try:
                genai.configure(api_key=self.api_key)
                # Using gemini-3.5-flash as default cost-effective fast model
                self.model = genai.GenerativeModel("gemini-3.5-flash")
                self.available = True
                logger.info("Successfully configured Gemini API client with RAG support.")
            except Exception as e:
                logger.error(f"Error configuring Gemini API client: {e}")

    def correct_text_gemini(self, text: str) -> dict:
        """Corrects grammar in text using Gemini, augmented with retrieved grammar rules.

        Args:
            text: Input string.

        Returns:
            Dictionary containing 'corrected', 'explanation' and optional diff.
        """
        if not self.available:
            raise RuntimeError("Gemini API key is not configured or client initialization failed.")

        # RAG phase: Retrieve closest grammar rule reference
        retrieved_rules = self.vector_db.retrieve(text, top_k=1)
        grammar_context = ""
        if retrieved_rules:
            rule = retrieved_rules[0]
            grammar_context = (
                f"\n\n--- Hướng dẫn tham khảo Ngữ pháp (RAG Context) ---\n"
                f"Tên quy tắc: {rule['name']}\n"
                f"Mô tả quy tắc: {rule['description']}\n"
                f"Yêu cầu: Hãy đối chiếu lỗi sai trong câu với mô tả quy tắc trên. Viết phần giải thích 'explanation' bằng tiếng Việt ngắn gọn, dễ hiểu dựa trên mô tả quy tắc ngữ pháp này."
            )

        prompt = (
            f"Analyze and correct the English grammar in the following text: '{text}'. "
            "Format the response EXACTLY as a JSON object with these keys: "
            "'corrected' (the corrected text, or the original text if no errors exist), "
            "'explanation' (a brief explanation of the errors in Vietnamese). "
            "Return only the raw JSON. Do not include markdown code block syntax."
            f"{grammar_context}"
        )

        try:
            response = self.model.generate_content(prompt)
            raw_text = response.text.strip()
            
            # Clean markdown code blocks if present
            if raw_text.startswith("```"):
                lines = raw_text.split("\n")
                raw_text = "\n".join(lines[1:-1]) if lines[-1].startswith("```") else "\n".join(lines[1:])
                
            data = json.loads(raw_text.strip())
            return {
                "corrected": data.get("corrected", text),
                "explanation": data.get("explanation", "Không có lỗi sai nào được phát hiện.")
            }
        except Exception as e:
            logger.error(f"Gemini correction API request failed: {e}")
            raise
