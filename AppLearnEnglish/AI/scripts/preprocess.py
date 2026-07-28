# -*- coding: utf-8 -*-

"""Preprocessing pipeline for GEC Datasets.

This script parses raw GEC files (JFLEG, FCE, BEA-2019), normalizes and cleans
the text content, validates samples, splits unsplit corpora into 80/10/10 sets,
and saves the final datasets as train.jsonl, validation.jsonl, and test.jsonl.
"""

import sys
import logging
import json
import random
import unicodedata
from pathlib import Path
from typing import Dict, List, Set, Tuple

# Fix namespace conflict by adjusting sys.path so we can import parsers
sys.path.append(str(Path(__file__).resolve().parent.parent / "parsers"))
from base_parser import BaseParser
from jfleg_parser import JFLEGParser
from fce_parser import FCEParser
from bea_parser import BEAParser

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("PreprocessPipeline")

# MARK: - Configuration

class PreprocessConfig:
    """Hyperparameters and configuration settings for data engineering."""
    EXCLUDE_IDENTICAL: bool = True     # Skip samples where input (sans prefix) == target
    MAX_TOKEN_LENGTH: int = 150       # Max word count per sentence
    MAX_CHAR_LENGTH: int = 1000       # Max character length per sentence
    RANDOM_SEED: int = 42
    TRAIN_RATIO: float = 0.8
    VAL_RATIO: float = 0.1
    TEST_RATIO: float = 0.1

# MARK: - Pipeline Core

class PreprocessPipeline:
    """Orchestrates parsing, cleaning, validation, splitting, and stats reporting."""

    def __init__(self, base_dir: str = "datasets") -> None:
        """Initializes pipeline with folder paths.

        Args:
            base_dir: Path to the datasets base directory.
        """
        self.base_path = Path(base_dir)
        self.raw_path = self.base_path / "raw"
        self.processed_path = self.base_path / "processed"
        self.log_path = self.base_path / "logs"

        # Ensure folders exist
        self.processed_path.mkdir(parents=True, exist_ok=True)
        self.log_path.mkdir(parents=True, exist_ok=True)

        # Initialize parsers
        self.parsers: Dict[str, BaseParser] = {
            "jfleg": JFLEGParser(),
            "fce": FCEParser(),
            "bea": BEAParser()
        }

        # Stats counters
        self.stats = {
            "total_raw_samples": 0,
            "samples_by_dataset": {},
            "duplicates_removed": 0,
            "samples_filtered": 0,
            "train_size": 0,
            "val_size": 0,
            "test_size": 0,
            "avg_token_len": 0.0,
            "max_char_len": 0,
            "min_char_len": sys.maxsize
        }

    def clean_text(self, text: str) -> str:
        """Applies Unicode NFKC normalization, whitespace compression, and control char removal.

        Args:
            text: The raw input text.

        Returns:
            The normalized and cleaned text string.
        """
        # Normalize Unicode
        text = unicodedata.normalize("NFKC", text)
        
        # Remove control characters
        text = "".join(ch for ch in text if not unicodedata.category(ch).startswith("C"))
        
        # Normalize whitespace (strip & compress multiple spaces)
        text = " ".join(text.split())
        return text

    def validate_sample(self, input_text: str, target_text: str) -> bool:
        """Validates that a parsed pair matches token length boundaries and character filters.

        Args:
            input_text: The source sentence (with 'Fix grammar: ' prefix).
            target_text: The reference corrected sentence.

        Returns:
            True if sample is valid, False otherwise.
        """
        # Strip the prefix to check actual text properties
        raw_input = input_text.replace("Fix grammar: ", "").strip()
        raw_target = target_text.strip()

        if not raw_input or not raw_target:
            return False

        # Exclude identical pairs if configured
        if PreprocessConfig.EXCLUDE_IDENTICAL and raw_input == raw_target:
            return False

        # Check lengths
        input_tokens = raw_input.split()
        target_tokens = raw_target.split()

        if len(input_tokens) > PreprocessConfig.MAX_TOKEN_LENGTH or len(target_tokens) > PreprocessConfig.MAX_TOKEN_LENGTH:
            return False

        if len(raw_input) > PreprocessConfig.MAX_CHAR_LENGTH or len(raw_target) > PreprocessConfig.MAX_CHAR_LENGTH:
            return False

        return True

    def process_all(self) -> None:
        """Runs the entire pipeline from raw directory scan to split files generation."""
        logger.info("Initializing Preprocessing Pipeline...")

        # Temporary lists to hold split buckets
        train_pool: List[Dict[str, str]] = []
        val_pool: List[Dict[str, str]] = []
        test_pool: List[Dict[str, str]] = []
        
        # Track unique pairs globally to deduplicate
        seen_pairs: Set[Tuple[str, str]] = set()
        lengths: List[int] = []

        # Scan each dataset raw folder
        for dataset_key, parser in self.parsers.items():
            dataset_dir = self.raw_path / dataset_key
            if not dataset_dir.exists():
                logger.warning(f"Raw dataset folder '{dataset_dir}' does not exist. Skipping.")
                continue

            logger.info(f"Parsing files for dataset: {parser.source_name}...")
            
            # Temporary split pools for this specific dataset
            ds_train: List[Dict[str, str]] = []
            ds_val: List[Dict[str, str]] = []
            ds_test: List[Dict[str, str]] = []
            ds_unsplit: List[Dict[str, str]] = []

            # Gather all files in this dataset folder (.json, .jsonl, .m2, .txt)
            for file_path in dataset_dir.rglob("*"):
                if not file_path.is_file() or file_path.name.startswith("."):
                    continue
                
                # Parse file
                try:
                    file_samples = parser.parse_file(file_path)
                except Exception as e:
                    logger.error(f"Failed parsing file {file_path}: {e}")
                    continue

                if not file_samples:
                    continue

                logger.info(f"Parsed {len(file_samples)} raw samples from: {file_path.name}")
                self.stats["total_raw_samples"] += len(file_samples)

                # Clean & validate
                for sample in file_samples:
                    cleaned_in = self.clean_text(sample["input"])
                    cleaned_out = self.clean_text(sample["target"])

                    if not self.validate_sample(cleaned_in, cleaned_out):
                        self.stats["samples_filtered"] += 1
                        continue

                    # Deduplicate check
                    pair = (cleaned_in, cleaned_out)
                    if pair in seen_pairs:
                        self.stats["duplicates_removed"] += 1
                        continue
                    seen_pairs.add(pair)

                    processed_sample = {
                        "input": cleaned_in,
                        "target": cleaned_out,
                        "source": sample["source"]
                    }

                    # Track lengths for reporting stats
                    char_len = len(cleaned_in.replace("Fix grammar: ", ""))
                    lengths.append(char_len)
                    self.stats["max_char_len"] = max(self.stats["max_char_len"], char_len)
                    self.stats["min_char_len"] = min(self.stats["min_char_len"], char_len)

                    # Determine split category based on filename
                    fname = file_path.name.lower()
                    if "train" in fname:
                        ds_train.append(processed_sample)
                    elif "val" in fname or "dev" in fname:
                        ds_val.append(processed_sample)
                    elif "test" in fname:
                        ds_test.append(processed_sample)
                    else:
                        ds_unsplit.append(processed_sample)

            # Record stats by dataset
            total_ds_samples = len(ds_train) + len(ds_val) + len(ds_test) + len(ds_unsplit)
            self.stats["samples_by_dataset"][parser.source_name] = total_ds_samples

            # Apply random splitting to unsplit data pools
            if ds_unsplit:
                logger.info(f"Splitting {len(ds_unsplit)} unsplit samples for {parser.source_name}...")
                random.seed(PreprocessConfig.RANDOM_SEED)
                random.shuffle(ds_unsplit)

                n_total = len(ds_unsplit)
                n_train = int(n_total * PreprocessConfig.TRAIN_RATIO)
                n_val = int(n_total * PreprocessConfig.VAL_RATIO)

                ds_train.extend(ds_unsplit[:n_train])
                ds_val.extend(ds_unsplit[n_train:n_train + n_val])
                ds_test.extend(ds_unsplit[n_train + n_val:])

            train_pool.extend(ds_train)
            val_pool.extend(ds_val)
            test_pool.extend(ds_test)

        # Shuffle the pooled training splits to ensure balanced distribution
        random.seed(PreprocessConfig.RANDOM_SEED)
        random.shuffle(train_pool)

        # Fallback split: if train_pool is empty, perform a global 80/10/10 split on all parsed samples
        if not train_pool:
            logger.warning("Train split is empty. Pooling all available samples to perform a global 80/10/10 split.")
            all_samples = train_pool + val_pool + test_pool
            random.shuffle(all_samples)
            
            n_total = len(all_samples)
            n_train = int(n_total * PreprocessConfig.TRAIN_RATIO)
            n_val = int(n_total * PreprocessConfig.VAL_RATIO)
            
            train_pool = all_samples[:n_train]
            val_pool = all_samples[n_train:n_train + n_val]
            test_pool = all_samples[n_train + n_val:]

        self.stats["train_size"] = len(train_pool)
        self.stats["val_size"] = len(val_pool)
        self.stats["test_size"] = len(test_pool)

        if lengths:
            self.stats["avg_token_len"] = sum(lengths) / len(lengths)
        else:
            self.stats["min_char_len"] = 0

        # MARK: - Save splits as JSON Lines
        self._write_jsonl(self.processed_path / "train.jsonl", train_pool)
        self._write_jsonl(self.processed_path / "validation.jsonl", val_pool)
        self._write_jsonl(self.processed_path / "test.jsonl", test_pool)

        # Generate report
        self._generate_report()
        logger.info("Preprocessing complete. Stats report generated successfully.")

    def _write_jsonl(self, file_path: Path, data: List[Dict[str, str]]) -> None:
        """Writes list of dictionaries to .jsonl file format.

        Args:
            file_path: Output target path.
            data: List of dictionary samples.
        """
        logger.info(f"Writing {len(data)} samples to: {file_path}")
        with open(file_path, "w", encoding="utf-8") as f:
            for item in data:
                f.write(json.dumps(item, ensure_ascii=False) + "\n")

    def _generate_report(self) -> None:
        """Writes detailed statistics summary text log report."""
        report_file = self.log_path / "preprocess_report.txt"
        
        # Ensure log path exists
        report_file.parent.mkdir(parents=True, exist_ok=True)
        
        with open(report_file, "w", encoding="utf-8") as f:
            f.write("========================================\n")
            f.write("GEC PREPROCESSING PIPELINE STATISTICS REPORT\n")
            f.write("========================================\n\n")
            
            f.write(f"Total Raw Samples Found: {self.stats['total_raw_samples']}\n")
            f.write(f"Duplicates Removed:      {self.stats['duplicates_removed']}\n")
            f.write(f"Samples Filtered (Max len/Identical): {self.stats['samples_filtered']}\n\n")
            
            f.write("Samples Count by Dataset:\n")
            for ds, count in self.stats["samples_by_dataset"].items():
                f.write(f"  - {ds}: {count} processed samples\n")
            f.write("\n")
            
            f.write("Generated Splits Details:\n")
            f.write(f"  - Train:      {self.stats['train_size']} lines/samples\n")
            f.write(f"  - Validation: {self.stats['val_size']} lines/samples\n")
            f.write(f"  - Test:       {self.stats['test_size']} lines/samples\n\n")
            
            f.write("Character Metrics (Source Sentences):\n")
            f.write(f"  - Avg Length:  {self.stats['avg_token_len']:.2f} characters\n")
            f.write(f"  - Max Length:  {self.stats['max_char_len']} characters\n")
            f.write(f"  - Min Length:  {self.stats['min_char_len']} characters\n")
            f.write("\n========================================\n")

# MARK: - Main CLI Execution

def main() -> None:
    # Use relative default paths aligned with execution within AppLearnEnglish/AI
    pipeline = PreprocessPipeline()
    pipeline.process_all()

if __name__ == "__main__":
    main()
