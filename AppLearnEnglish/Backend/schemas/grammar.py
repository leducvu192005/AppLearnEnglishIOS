# -*- coding: utf-8 -*-

"""Pydantic Request & Response schemas for GEC.

Maintains structural definitions for data validation and frontend compatibility.
"""

from typing import List, Optional
from pydantic import BaseModel, Field

class ChangeItem(BaseModel):
    """Represents a single corrected grammar edit."""
    wrong: str = Field(..., description="The original incorrect word(s)")
    correct: str = Field(..., description="The corrected word(s)")
    reason: str = Field(..., description="Brief explanation of the edit")

class CorrectionRequest(BaseModel):
    """Incoming request body containing input text to correct."""
    text: str = Field(..., description="Original text input from user")

class CorrectionResponse(BaseModel):
    """Outgoing response body containing corrected text and list of changes."""
    original: str = Field(..., description="The original text input")
    corrected: str = Field(..., description="The grammatically corrected text output")
    explanation: str = Field(..., description="General summary or fallback explanation")
    changes: List[ChangeItem] = Field(default=[], description="Structured list of edits made")
