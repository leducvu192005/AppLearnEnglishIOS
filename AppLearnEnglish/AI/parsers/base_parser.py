# -*- coding: utf-8 -*-

"""Base GEC Dataset Parser module.

This module defines the abstract BaseParser class that all GEC dataset parsers
must inherit from, including reusable helpers for parsing M2 format files.
"""

import abc
from pathlib import Path
from typing import Dict, List

class BaseParser(abc.ABC):
    """Abstract base class for parsing GEC datasets into standard formats."""

    def __init__(self, source_name: str) -> None:
        """Initializes the parser with its source name identifier.

        Args:
            source_name: Name of the dataset (e.g., 'JFLEG', 'FCE', 'BEA-2019').
        """
        self.source_name = source_name

    @abc.abstractmethod
    def parse_file(self, file_path: Path) -> List[Dict[str, str]]:
        """Parses a specific GEC corpus file.

        Args:
            file_path: Path to the file to parse.

        Returns:
            A list of dictionary samples, each containing 'input', 'target', and 'source'.
        """
        pass

    def validate_sample(self, input_text: str, target_text: str) -> bool:
        """Helper validation hook to inspect basic text sanity.

        Args:
            input_text: The incorrect sentence.
            target_text: The corrected reference sentence.

        Returns:
            True if sample passes validation checks, False otherwise.
        """
        if not input_text.strip() or not target_text.strip():
            return False
        return True

    def parse_m2_format(self, file_path: Path) -> List[Dict[str, str]]:
        """Parses a standard GEC M2 format file.

        Args:
            file_path: Path to the M2 file.

        Returns:
            A list of parsed samples.
        """
        samples: List[Dict[str, str]] = []
        if not file_path.exists():
            return samples

        try:
            with open(file_path, "r", encoding="utf-8") as f:
                m2_block: List[str] = []
                for line in f:
                    line = line.strip()
                    if not line:
                        if m2_block:
                            samples.extend(self._process_m2_block(m2_block))
                            m2_block = []
                    else:
                        m2_block.append(line)
                if m2_block:
                    samples.extend(self._process_m2_block(m2_block))
        except Exception as e:
            raise RuntimeError(f"Error parsing M2 file at {file_path}: {str(e)}") from e

        return samples

    def _process_m2_block(self, block: List[str]) -> List[Dict[str, str]]:
        """Applies annotation edits from an M2 block to reconstruct corrected sentences.

        Args:
            block: List of lines in a single sentence M2 block.

        Returns:
            List of parsed dictionary samples for each annotator.
        """
        source_line = block[0]
        if not source_line.startswith("S "):
            return []
            
        source_sentence = source_line[2:]
        source_tokens = source_sentence.split()
        
        # Group edits by annotator ID
        annotators_edits: Dict[int, List[tuple]] = {}
        
        for edit_line in block[1:]:
            if not edit_line.startswith("A "):
                continue
            parts = edit_line[2:].split("|||")
            if len(parts) < 3:
                continue
                
            offsets = parts[0].split()
            if len(offsets) < 2:
                continue
            start, end = int(offsets[0]), int(offsets[1])
            if start == -1:
                continue
                
            correction = parts[2]
            # Group by annotator ID at the end of the line
            annotator_id = int(parts[-1]) if parts[-1].isdigit() else 0
            
            if annotator_id not in annotators_edits:
                annotators_edits[annotator_id] = []
            annotators_edits[annotator_id].append((start, end, correction))
            
        samples: List[Dict[str, str]] = []
        
        # If no edits, source equals target
        if not annotators_edits:
            if self.validate_sample(source_sentence, source_sentence):
                samples.append({
                    "input": f"Fix grammar: {source_sentence}",
                    "target": source_sentence,
                    "source": self.source_name
                })
            return samples
            
        for annotator_id, edits in annotators_edits.items():
            # Sort edits in reverse order by start offset to prevent indexing shifts
            edits.sort(key=lambda x: x[0], reverse=True)
            
            tokens = list(source_tokens)
            for start, end, corr in edits:
                corr_tokens = corr.split() if corr else []
                tokens[start:end] = corr_tokens
                
            corrected_sentence = " ".join(tokens)
            
            if self.validate_sample(source_sentence, corrected_sentence):
                samples.append({
                    "input": f"Fix grammar: {source_sentence}",
                    "target": corrected_sentence,
                    "source": self.source_name
                })
                
        return samples
