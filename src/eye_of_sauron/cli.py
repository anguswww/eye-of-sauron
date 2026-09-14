"""Command-line interface for Eye of Sauron."""

import argparse
from collections.abc import Sequence

from eye_of_sauron import __version__
from eye_of_sauron.ping_control import PingControlError, ping_is_blocked, set_ping_allowed


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
    subparsers = parser.add_subparsers(dest="command")
    ping_parser = subparsers.add_parser(
        "ping",
        help="control attacker-to-target ping traffic",
        description="Allow, block, or inspect ping traffic through the IDS lab router.",
    )
    ping_parser.add_argument(
        "state",
        choices=("on", "off", "status"),
        help="on allows ping, off blocks ping, and status reports the current policy",
    )
    return parser


def main(argv: Sequence[str] | None = None) -> int:
    """Run the command-line interface."""
    args = build_parser().parse_args(argv)
    if args.command != "ping":
        return 0

    try:
        if args.state == "status":
            print("ping is off (blocked)" if ping_is_blocked() else "ping is on (allowed)")
            return 0

        allowed = args.state == "on"
        changed = set_ping_allowed(allowed=allowed)
        policy = "on (allowed)" if allowed else "off (blocked)"
        suffix = "" if changed else " (already set)"
        print(f"ping is {policy}{suffix}")
        return 0
    except PingControlError as error:
        print(f"error: {error}")
        print("Run this command as root on the IDS VM, for example with sudo.")
        return 1
