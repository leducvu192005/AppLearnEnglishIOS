# -*- coding: utf-8 -*-

"""FCE GEC Dataset Parser module.

This module implements the FCEParser class to parse First Certificate in English
GEC files.
"""

from pathlib import Path
from typing import Dict, List
from base_parser import BaseParser

class FCEParser(BaseParser):
    """Parser specifically for FCE GEC dataset files."""

    def __init__(self) -> None:
        """Initializes the FCE parser with its dataset source identifier."""
        super().__init__(source_name="FCE")

    def parse_file(self, file_path: Path) -> List[Dict[str, str]]:
        """Parses an FCE file, supporting both standard M2 and plain text.

        Args:
            file_path: Path to the FCE dataset file.

        Returns:
            A list of dictionary samples, each containing 'input', 'target', and 'source'.
        """
        # If it's an M2 file, parse it using the base M2 helper
        if file_path.suffix == ".m2":
            return self.parse_m2_format(file_path)
            
        # Fallback: parse plain text source/target files if they are named accordingly
        samples: List[Dict[str, str]] = []
        if not file_path.exists():
            return samples
            
        try:
            # Simple line-by-line fallback for txt files if formatted as parallel sentences
            with open(file_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    # Assumes a tab-separated format for simple fallback files: "source\ttarget"
                    parts = line.split("\t")
                    if len(parts) >= 2:
                        src, tgt = parts[0], parts[1]
                        if self.validate_sample(src, tgt):
                            samples.append({
                                "input": f"Fix grammar: {src}",
                                "target": tgt,
                                "source": self.source_name
                            })
        except Exception as e:
            raise RuntimeError(f"Error parsing FCE text file at {file_path}: {str(e)}") from e
            
        return samples
