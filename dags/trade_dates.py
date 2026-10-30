"""Trade-date resolution for market-bars DAGs. No Airflow imports."""

from __future__ import annotations

from datetime import date, datetime, timedelta
from zoneinfo import ZoneInfo

_NY = ZoneInfo("America/New_York")


def default_trade_date(now_ny: date | None = None) -> date:
    """America/New_York calendar today minus one day."""
    if now_ny is None:
        now_ny = datetime.now(_NY).date()
    return now_ny - timedelta(days=1)


def resolve_trade_date(
    param: str | date | None,
    *,
    now_ny: date | None = None,
) -> date:
    """Use an explicit YYYY-MM-DD (or date) when set; otherwise the NY default."""
    if param is None or param == "":
        return default_trade_date(now_ny=now_ny)
    if isinstance(param, datetime):
        raise TypeError(
            f"Invalid trade_date {param!r}; expected date or YYYY-MM-DD string"
        )
    if isinstance(param, date):
        return param
    if isinstance(param, str):
        try:
            return date.fromisoformat(param)
        except ValueError as exc:
            raise ValueError(
                f"Invalid trade_date {param!r}; expected YYYY-MM-DD"
            ) from exc
    raise TypeError(f"Invalid trade_date {param!r}; expected date or YYYY-MM-DD string")


def _require_iso_date(param: str | date | None, *, name: str) -> date:
    if param is None or param == "":
        raise ValueError(f"{name} is required (YYYY-MM-DD)")
    if isinstance(param, datetime):
        raise TypeError(f"Invalid {name} {param!r}; expected date or YYYY-MM-DD string")
    if isinstance(param, date):
        return param
    if isinstance(param, str):
        try:
            return date.fromisoformat(param)
        except ValueError as exc:
            raise ValueError(f"Invalid {name} {param!r}; expected YYYY-MM-DD") from exc
    raise TypeError(f"Invalid {name} {param!r}; expected date or YYYY-MM-DD string")


def iter_trade_dates(
    start: str | date | None,
    end: str | date | None,
):
    """Yield inclusive calendar dates from start through end (YYYY-MM-DD or date).

    Raises ValueError when either bound is missing/empty or start > end.
    """
    start_d = _require_iso_date(start, name="start_date")
    end_d = _require_iso_date(end, name="end_date")
    if start_d > end_d:
        raise ValueError(
            f"start_date {start_d.isoformat()} must be <= end_date {end_d.isoformat()}"
        )
    current = start_d
    while current <= end_d:
        yield current
        current += timedelta(days=1)
