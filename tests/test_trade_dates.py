"""Hermetic tests for trade-date resolution (no Airflow / cloud)."""

from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

import pytest

_DAGS = Path(__file__).resolve().parents[1] / "dags"
if str(_DAGS) not in sys.path:
    sys.path.insert(0, str(_DAGS))

from trade_dates import (  # noqa: E402
    default_trade_date,
    iter_trade_dates,
    resolve_trade_date,
)


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


def test_iter_trade_dates_inclusive_range() -> None:
    assert list(iter_trade_dates("2024-01-01", "2024-01-03")) == [
        date(2024, 1, 1),
        date(2024, 1, 2),
        date(2024, 1, 3),
    ]


def test_iter_trade_dates_single_day() -> None:
    assert list(iter_trade_dates(date(2024, 5, 10), date(2024, 5, 10))) == [
        date(2024, 5, 10)
    ]


def test_iter_trade_dates_start_after_end_raises() -> None:
    with pytest.raises(ValueError, match="must be <="):
        list(iter_trade_dates("2024-01-05", "2024-01-01"))


def test_iter_trade_dates_missing_bounds_raise() -> None:
    with pytest.raises(ValueError, match="start_date is required"):
        list(iter_trade_dates(None, "2024-01-01"))
    with pytest.raises(ValueError, match="end_date is required"):
        list(iter_trade_dates("2024-01-01", ""))
