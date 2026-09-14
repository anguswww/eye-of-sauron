"""Eye of Sauron intrusion detection system."""

from importlib.metadata import PackageNotFoundError, version

try:
    __version__ = version("eye-of-sauron")
except PackageNotFoundError:  # pragma: no cover - only possible outside an installation
    __version__ = "0.0.0"

__all__ = ["__version__"]
