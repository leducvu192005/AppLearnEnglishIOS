#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Download and manage GEC datasets.

This script implements the DatasetManager class which automates downloading,
verifying, listing, and removing GEC corpora (BEA-2019, FCE, JFLEG).
"""

import sys
import logging
import argparse
import shutil
import urllib.request
import tarfile
import zipfile
from pathlib import Path
from typing import Dict, Any, Optional, List

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("DatasetManager")

# MARK: - Dataset Configuration Registry

DATASETS_CONFIG: Dict[str, Dict[str, Any]] = {
    "jfleg": {
        "name": "JFLEG",
        "description": "JFLEG: JHU Fluency-Evaluation GEC Dataset",
        "type": "huggingface",
        "hf_path": "jhu-clsp/jfleg",
        "auto": True
    },
    "fce": {
        "name": "FCE",
        "description": "FCE: First Certificate in English dataset",
        "type": "manual",
        "auto": False,
        "instructions": (
            "1. Visit the Cambridge FCE public dataset official website.\n"
            "2. Request or download the 'fce_public.tar.gz' archive file.\n"
            "3. Extract and place the dataset split files into 'datasets/raw/fce/'."
        )
    },
    "bea": {
        "name": "BEA-2019",
        "description": "BEA-2019: Building Educational Applications Shared Task GEC Dataset",
        "type": "manual",
        "auto": False,
        "instructions": (
            "1. Visit the BEA-2019 official website: https://www.cl.cam.ac.uk/research/nl/bea2019/sharedtask/\n"
            "2. Fill in the request form and download the data zip archive.\n"
            "3. Extract the contents into 'datasets/raw/bea/'."
        )
    },
    "lang8": {
        "name": "Lang-8",
        "description": "Lang-8 Learner Corpora",
        "type": "manual",
        "auto": False,
        "instructions": (
            "1. Access the Lang-8 corpus request form at: https://lang-8.com/\n"
            "2. Obtain raw text dump files.\n"
            "3. Place them into 'datasets/raw/lang8/'."
        )
    },
    "gyafc": {
        "name": "GYAFC",
        "description": "Grammarly Yahoo Answers Formality Corpus",
        "type": "manual",
        "auto": False,
        "instructions": (
            "1. Request access from Grammarly Research team.\n"
            "2. Download zip and extract to 'datasets/raw/gyafc/'."
        )
    }
}

# MARK: - DatasetManager Class

class DatasetManager:
    """Manages downloading, listing, verifying, and cleanups of GEC datasets."""

    def __init__(self, base_dir: str = "datasets") -> None:
        """Initializes the manager with base directory paths.

        Args:
            base_dir: Base directory path for datasets.
        """
        self.base_path = Path(base_dir)
        self.raw_path = self.base_path / "raw"
        self.download_cache = self.raw_path / "downloads"
        
        # Ensure directories exist
        self.raw_path.mkdir(parents=True, exist_ok=True)
        self.download_cache.mkdir(parents=True, exist_ok=True)

    def get_dataset_path(self, dataset_key: str) -> Path:
        """Gets the raw directory destination path for a given dataset key.

        Args:
            dataset_key: Registry identifier for the dataset.

        Returns:
            Path object pointing to dataset folder.
        """
        return self.raw_path / dataset_key

    def list_datasets(self) -> List[str]:
        """Lists all supported dataset keys registered in config.

        Returns:
            List of registered dataset keys.
        """
        return list(DATASETS_CONFIG.keys())

    def download_dataset(self, dataset_key: str) -> bool:
        """Downloads the specified dataset if configured for auto-downloads.

        Args:
            dataset_key: Registry identifier for the dataset.

        Returns:
            True if download succeeded/already exists, False otherwise.
        """
        if dataset_key not in DATASETS_CONFIG:
            logger.error(f"Dataset '{dataset_key}' is not registered in the system.")
            return False
            
        config = DATASETS_CONFIG[dataset_key]
        dest_dir = self.get_dataset_path(dataset_key)
        
        # Check if already present
        if dest_dir.exists() and any(dest_dir.iterdir()):
            logger.info(f"Dataset '{config['name']}' already exists at: {dest_dir}. Skipping download.")
            return True
            
        if not config["auto"]:
            logger.warning(f"Dataset '{config['name']}' requires manual download steps:")
            print("\n" + "=" * 50)
            print(f"MANUAL ACCESS INSTRUCTIONS FOR {config['name']}:")
            print(config["instructions"])
            print("=" * 50 + "\n")
            return False

        logger.info(f"Starting automated download process for: {config['name']}...")
        dest_dir.mkdir(parents=True, exist_ok=True)

        try:
            if config["type"] == "huggingface":
                return self._download_from_huggingface(config["hf_path"], dest_dir)
            elif config["type"] == "url":
                return self._download_from_url(config["url"], config["filename"], dest_dir)
        except Exception as e:
            logger.error(f"An error occurred while downloading '{config['name']}': {str(e)}")
            # Cleanup on failure
            if dest_dir.exists():
                shutil.rmtree(dest_dir)
            return False
            
        return False

    def _download_from_huggingface(self, hf_path: str, dest_dir: Path) -> bool:
        """Helper to download and serialize dataset from Hugging Face.

        Args:
            hf_path: Hugging Face dataset identifier.
            dest_dir: Target output directory.
        """
        logger.info(f"Downloading '{hf_path}' using Hugging Face datasets library...")
        try:
            # Avoid namespace conflict with the local 'datasets/' directory
            import sys
            original_path = sys.path.copy()
            sys.path = [p for p in sys.path if p != "" and p != "." and not p.endswith("/AI") and not p.endswith("\\AI")]
            
            from datasets import load_dataset
            
            # Restore sys.path
            sys.path = original_path
            # Download dataset splits
            dataset = load_dataset(hf_path, trust_remote_code=True)
            
            # Save splits locally as json files
            for split_name, split_data in dataset.items():
                out_file = dest_dir / f"{split_name}.json"
                logger.info(f"Saving split '{split_name}' to: {out_file}")
                split_data.to_json(out_file)
                
            return True
        except Exception as e:
            logger.error(f"Failed to load datasets package or download splits: {str(e)}", exc_info=True)
            return False

    def _download_from_url(self, url: str, filename: str, dest_dir: Path) -> bool:
        """Helper to download from a direct URL link and extract archives.

        Args:
            url: Remote direct download link.
            filename: Output filename for caching.
            dest_dir: Target extraction folder.
        """
        cache_file = self.download_cache / filename
        
        if not cache_file.exists():
            logger.info(f"Downloading archive from: {url}")
            
            # Dynamic download tracking
            def progress_callback(block_num: int, block_size: int, total_size: int):
                downloaded = block_num * block_size
                if total_size > 0:
                    percent = min(100, int(downloaded * 100 / total_size))
                    sys.stdout.write(f"\rDownloading: {percent}% completed ({downloaded}/{total_size} bytes)")
                    sys.stdout.flush()
                else:
                    sys.stdout.write(f"\rDownloading: {downloaded} bytes received")
                    sys.stdout.flush()
            
            urllib.request.urlretrieve(url, cache_file, progress_callback)
            print() # Clear line
            logger.info("Download completed successfully.")
            
        # Extract archive based on file extension
        logger.info(f"Extracting archive contents to: {dest_dir}")
        if filename.endswith(".tar.gz") or filename.endswith(".tgz"):
            with tarfile.open(cache_file, "r:gz") as tar:
                tar.extractall(path=dest_dir)
        elif filename.endswith(".zip"):
            with zipfile.ZipFile(cache_file, "r") as zip_ref:
                zip_ref.extractall(dest_dir)
        else:
            # Copy as is if not compressed
            shutil.copy(cache_file, dest_dir / filename)
            
        return True

    def verify_dataset(self, dataset_key: str) -> bool:
        """Verifies integrity, computes folder sizes, and counts samples.

        Args:
            dataset_key: Registry identifier for the dataset.

        Returns:
            True if dataset is present and verified, False otherwise.
        """
        if dataset_key not in DATASETS_CONFIG:
            return False
            
        config = DATASETS_CONFIG[dataset_key]
        dest_dir = self.get_dataset_path(dataset_key)
        
        if not dest_dir.exists() or not any(dest_dir.iterdir()):
            print(f"\n========================================\n"
                  f"{config['name']}\n"
                  f"Status: MISSING (Not downloaded)\n"
                  f"========================================\n")
            return False
            
        # Compute directory size
        total_size = sum(f.stat().st_size for f in dest_dir.rglob("*") if f.is_file())
        size_mb = total_size / (1024 * 1024)
        
        # Verify splits and formats
        files_list = [f.name for f in dest_dir.iterdir() if f.is_file()]
        samples_count: Dict[str, str] = {"Train": "N/A", "Validation": "N/A", "Test": "N/A"}
        
        # Check files content size / lines count
        for file in dest_dir.rglob("*"):
            if not file.is_file():
                continue
            fname = file.name.lower()
            split_key = None
            if "train" in fname:
                split_key = "Train"
            elif "val" in fname or "dev" in fname:
                split_key = "Validation"
            elif "test" in fname:
                split_key = "Test"
                
            if split_key:
                try:
                    # Count rows/lines for sample sizes estimation
                    with open(file, "r", encoding="utf-8", errors="ignore") as f:
                        lines = sum(1 for _ in f)
                    samples_count[split_key] = f"{lines} lines/samples"
                except Exception:
                    pass

        # Print audit report
        print(f"\n========================================")
        print(f"{config['name']}")
        print(f"Status: OK")
        print(f"\nSamples:")
        print(f"Train: {samples_count['Train']}")
        print(f"Validation: {samples_count['Validation']}")
        print(f"Test: {samples_count['Test']}")
        print(f"\nDirectory Details:")
        print(f"Path: {dest_dir.resolve()}")
        print(f"Files: {files_list}")
        print(f"Total Size: {size_mb:.2f} MB")
        print(f"========================================\n")
        
        return True

    def remove_dataset(self, dataset_key: str) -> None:
        """Removes the target dataset folder.

        Args:
            dataset_key: Registry identifier for the dataset.
        """
        dest_dir = self.get_dataset_path(dataset_key)
        if dest_dir.exists():
            logger.info(f"Removing dataset folder: {dest_dir}")
            shutil.rmtree(dest_dir)
        else:
            logger.warning(f"Dataset folder does not exist: {dest_dir}")

# MARK: - Main CLI Execution

def main() -> None:
    parser = argparse.ArgumentParser(description="GEC Dataset Downloader and Manager CLI.")
    parser.add_argument(
        "--dataset", 
        type=str, 
        choices=list(DATASETS_CONFIG.keys()), 
        help="Target registered dataset key to download and verify."
    )
    parser.add_argument(
        "--list", 
        action="store_true", 
        help="List all supported registered GEC datasets."
    )
    parser.add_argument(
        "--verify-all", 
        action="store_true", 
        help="Verify all downloaded GEC datasets in base directory."
    )
    
    args = parser.parse_args()
    manager = DatasetManager()
    
    if args.list:
        print("\nRegistered Datasets:")
        for key, conf in DATASETS_CONFIG.items():
            mode = "Auto-downloadable" if conf["auto"] else "Manual"
            print(f"- {key}: {conf['name']} ({mode}) - {conf['description']}")
        print()
        sys.exit(0)
        
    if args.verify_all:
        print("\nAuditing active GEC datasets:")
        for key in DATASETS_CONFIG.keys():
            manager.verify_dataset(key)
        sys.exit(0)
        
    if args.dataset:
        success = manager.download_dataset(args.dataset)
        if success:
            manager.verify_dataset(args.dataset)
        else:
            logger.error(f"Failed loading or downloading dataset: {args.dataset}")
            sys.exit(1)
    else:
        # Default behavior: run on jfleg as standard test if no option specified
        logger.info("No option selected. Running standard test verification on jfleg.")
        manager.download_dataset("jfleg")
        manager.verify_dataset("jfleg")

if __name__ == "__main__":
    main()
