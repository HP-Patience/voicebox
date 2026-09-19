"""Run from the repository root: python -m scripts.check_qwen_model [--offline]."""

import argparse
import asyncio
import os
from pathlib import Path

from dotenv import load_dotenv


def main():
    parser = argparse.ArgumentParser(description="Load Qwen 0.6B using the real Voicebox backend.")
    parser.add_argument("--offline", action="store_true", help="Verify the cache without Hugging Face network access.")
    args = parser.parse_args()
    load_dotenv(Path(__file__).resolve().parents[1] / ".env")
    if args.offline:
        os.environ["HF_HUB_OFFLINE"] = "1"
        os.environ["TRANSFORMERS_OFFLINE"] = "1"

    # Apply Voicebox's cache setting before any Hugging Face imports.
    from backend import config  # noqa: F401
    from backend.backends.pytorch_backend import PyTorchTTSBackend
    from huggingface_hub import constants

    print(f"Model cache: {constants.HF_HUB_CACHE}")
    model = PyTorchTTSBackend(model_size="0.6B")
    asyncio.run(model.load_model())
    assert model.is_loaded(), "Qwen model did not load"
    print(f"PASS: Qwen 0.6B loaded on {model.device}; offline={args.offline}")
    model.unload_model()


if __name__ == "__main__":
    main()
