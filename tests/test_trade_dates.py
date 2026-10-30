"""Hermetic tests for trade-date resolution (no Airflow / cloud)."""

from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

import pytest

_DAGS = Path(__file__).resolve().parents[1] / "dags"
if str(_DAGS) not in sys.path:
    sys.path.insert(0, str(_DAGS))

from trade_dates import default_trade_date, resolve_trade_date  # noqa: E402


def test_default_trade_date_is_ny_today_minus_one() -> None:
    assert default_trade_date(now_ny=date(2024, 3, 15)) == date(2024, 3, 14)


def test_resolve_default_when_param_none_or_empty() -> None:
    now = date(2024, 6, 10)
    assert resolve_trade_date(None, now_ny=now) == date(2024, 6, 9)
    assert resolve_trade_date("", now_ny=now) == date(2024, 6, 9)


def test_resolve_explicit_iso_wins() -> None:
    now = date(2024, 6, 10)
    assert resolve_trade_date("2024-01-02", now_ny=now) == date(2024, 1, 2)


def test_resolve_explicit_date_wins() -> None:
    now = date(2024, 6, 10)
    assert resolve_trade_date(date(2023, 12, 29), now_ny=now) == date(2023, 12, 29)


def test_resolve_invalid_iso_raises() -> None:
    with pytest.raises(ValueError, match="YYYY-MM-DD"):
        resolve_trade_date("03/15/2024")
