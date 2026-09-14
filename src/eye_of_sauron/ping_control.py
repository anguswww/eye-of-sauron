"""Control ICMP echo traffic across the IDS lab router."""

import subprocess
from collections.abc import Sequence

ATTACKER_IP = "192.168.56.10"
TARGET_IP = "192.168.57.20"
RULE_COMMENT = "eye-of-sauron-ping-block"

_RULE = (
    "-s",
    ATTACKER_IP,
    "-d",
    TARGET_IP,
    "-p",
    "icmp",
    "--icmp-type",
    "echo-request",
    "-m",
    "comment",
    "--comment",
    RULE_COMMENT,
    "-j",
    "REJECT",
    "--reject-with",
    "icmp-admin-prohibited",
)


class PingControlError(RuntimeError):
    """Raised when the firewall rule cannot be inspected or changed."""


def _iptables(arguments: Sequence[str]) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(
            ("iptables", "-w", *arguments),
            check=False,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError as error:
        raise PingControlError("iptables is not installed on this system") from error


def ping_is_blocked() -> bool:
    """Return whether the demo ping-block rule is installed."""
    result = _iptables(("-C", "FORWARD", *_RULE))
    if result.returncode in {0, 1}:
        return result.returncode == 0
    detail = result.stderr.strip() or "could not inspect the firewall"
    raise PingControlError(detail)


def set_ping_allowed(*, allowed: bool) -> bool:
    """Set the ping policy and return True when the firewall was changed."""
    blocked = ping_is_blocked()
    if allowed and blocked:
        operation = ("-D", "FORWARD", *_RULE)
    elif not allowed and not blocked:
        operation = ("-I", "FORWARD", "1", *_RULE)
    else:
        return False

    result = _iptables(operation)
    if result.returncode != 0:
        detail = result.stderr.strip() or "could not update the firewall"
        raise PingControlError(detail)
    return True
