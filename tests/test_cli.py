"""Tests for the Eye of Sauron command-line interface."""

import pytest

from eye_of_sauron import __version__
from eye_of_sauron.cli import main


def test_cli_accepts_no_arguments() -> None:
    assert main([]) == 0


def test_cli_reports_version(capsys: pytest.CaptureFixture[str]) -> None:
    with pytest.raises(SystemExit) as exit_info:
        main(["--version"])

    assert exit_info.value.code == 0
    assert capsys.readouterr().out.strip() == f"eye-of-sauron {__version__}"
