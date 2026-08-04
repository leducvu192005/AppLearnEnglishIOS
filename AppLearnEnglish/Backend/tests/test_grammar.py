# -*- coding: utf-8 -*-

"""Unit tests for GEC /api/correct Endpoint.

Tests data serialization, model response, and edits extraction.
"""

import sys
from pathlib import Path
from fastapi.testclient import TestClient

# Add Backend root folder to sys.path
sys.path.append(str(Path(__file__).resolve().parent.parent))
from main import app

client = TestClient(app)

def test_correct_grammar_endpoint() -> None:
    """Verifies that GEC API correctly corrects verbs and extracts structured changes."""
    response = client.post("/api/correct", json={"text": "She go to school."})
    
    assert response.status_code == 200, f"Expected 200, got {response.status_code}"
    
    data = response.json()
    assert "original" in data, "Response missing 'original' key"
    assert "corrected" in data, "Response missing 'corrected' key"
    assert "changes" in data, "Response missing 'changes' key"

    assert data["original"] == "She go to school.", "Original text mismatch"
    assert data["corrected"] == "She goes to school.", "Corrected text mismatch"
    
    changes = data["changes"]
    assert len(changes) > 0, "No changes detected, but sentence was ungrammatical"
    
    # Assert change elements match correctly
    assert changes[0]["wrong"] == "go", f"Expected incorrect word 'go', got '{changes[0]['wrong']}'"
    assert changes[0]["correct"] == "goes", f"Expected correct word 'goes', got '{changes[0]['correct']}'"
