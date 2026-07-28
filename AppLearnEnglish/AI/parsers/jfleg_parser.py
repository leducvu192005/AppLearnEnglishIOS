# -*- coding: utf-8 -*-

"""JFLEG GEC Dataset Parser module.

This module implements the JFLEGParser class to extract sentences from JFLEG JSON lines.
"""

import json
from pathlib import Path
from typing import Dict, List
from base_parser import BaseParser

class JFLEGParser(BaseParser):
    """Parser specifically for JFLEG GEC dataset files."""

    def __init__(self) -> None:
        """Initializes the JFLEG parser with its dataset source identifier."""
        super().__init__(source_name="JFLEG")

    def parse_file(self, file_path: Path) -> List[Dict[str, str]]:
        """Parses a JFLEG json lines file.

        Args:
            file_path: Path to the JFLEG JSON Lines file.

        Returns:
            A list of dictionary samples, each containing 'input', 'target', and 'source'.
        """
        samples: List[Dict[str, str]] = []
        
        if not file_path.exists():
            return samples
            
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                        
                    data = json.loads(line)
                    input_text = data.get("sentence", "")
                    corrections = data.get("corrections", [])
                    
                    # Create a sample pair for each available reference correction
                    for correction in corrections:
                        if self.validate_sample(input_text, correction):
                            samples.append({
                                "input": f"Fix grammar: {input_text}",
                                "target": correction,
                                "source": self.source_name
                            })
        except Exception as e:
            # Re-raise or catch depending on parser error boundaries
            raise RuntimeError(f"Error parsing JFLEG file at {file_path}: {str(e)}") from e
            
        return samples
