"""Command-line interface for Eye of Sauron."""

import argparse
from collections.abc import Sequence

from eye_of_sauron import __version__


def build_parser() -> argparse.ArgumentParser:
    """Build the command-line argument parser."""
    parser = argparse.ArgumentParser(
        prog="eye-of-sauron",
        description="Machine-learning intrusion detection system",
    )
    parser.add_argument(
        "--version",
        action="version",
        version=f"%(prog)s {__version__}",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    """Run the command-line interface."""
    build_parser().parse_args(argv)
    return 0
