# -*- coding: utf-8 -*-

"""BEA-2019 GEC Dataset Parser module.

This module implements the BEAParser class to parse BEA-2019 GEC files.
"""

from pathlib import Path
from typing import Dict, List
from base_parser import BaseParser

class BEAParser(BaseParser):
    """Parser specifically for BEA-2019 GEC dataset files."""

    def __init__(self) -> None:
        """Initializes the BEA-2019 parser with its dataset source identifier."""
        super().__init__(source_name="BEA-2019")

    def parse_file(self, file_path: Path) -> List[Dict[str, str]]:
        """Parses a BEA-2019 file, supporting both standard M2 and plain text.

        Args:
            file_path: Path to the BEA-2019 dataset file.

        Returns:
            A list of dictionary samples, each containing 'input', 'target', and 'source'.
        """
        if file_path.suffix == ".m2":
            return self.parse_m2_format(file_path)
            
        samples: List[Dict[str, str]] = []
        if not file_path.exists():
            return samples
            
        try:
            with open(file_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
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
            raise RuntimeError(f"Error parsing BEA text file at {file_path}: {str(e)}") from e
            
        return samples
