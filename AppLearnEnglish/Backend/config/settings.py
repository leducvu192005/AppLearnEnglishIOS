# -*- coding: utf-8 -*-

"""Configuration settings for FastAPI Backend.

Loads environment variables from .env file using Pydantic Settings.
"""

from pathlib import Path
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Base model name on Hugging Face
    BASE_MODEL: str = "google/flan-t5-base"
    
    # Path to local GEC fine-tuned LoRA adapters
    MODEL_PATH: str = str(Path(__file__).resolve().parent.parent.parent / "AI" / "checkpoints" / "checkpoint-final")
    
    # Computation device ("mps", "cuda", "cpu")
    DEVICE: str = "mps"
    
    # Sequence token limits
    MAX_INPUT_LENGTH: int = 128
    MAX_TARGET_LENGTH: int = 128
    
    # Google Gemini API Key fallback
    GEMINI_API_KEY: str = ""
    
    # PayOS Payment Gateway Configuration
    PAYOS_CLIENT_ID: str = ""
    PAYOS_API_KEY: str = ""
    PAYOS_CHECKSUM_KEY: str = ""
    FIREBASE_PROJECT_ID: str = "applearnenglishio"
    FIREBASE_API_KEY: str = "AIzaSyACC4zDt9CD_R1EGCmBrLd4MiRDo0y0ptc"

    class Config:
        env_file = ".env"
        extra = "ignore"

settings = Settings()
