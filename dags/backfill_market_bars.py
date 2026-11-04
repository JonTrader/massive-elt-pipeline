"""Manual sequential backfill for a calendar date range.

Walks start_date..end_date one day at a time (extract then load), then runs
dbt build once. Never uses Airflow logical_date for market dates.

Do not run this DAG for a trade_date that the daily DAG is currently processing.
If the loop fails mid-range, re-trigger with start_date at the failed date
(extract and load are idempotent per date).
"""

from __future__ import annotations

import subprocess
from datetime import date, timedelta
from pathlib import Path

import pendulum
from airflow.sdk import Param, dag, task
from trade_dates import iter_trade_dates

REPO_ROOT = Path("/opt/airflow/repo")
if not (REPO_ROOT / "transform").is_dir():
    # Host / non-compose layout: dags/ sits next to extract/ and transform/.
    candidate = Path(__file__).resolve().parents[1]
    if (candidate / "extract").is_dir() and (candidate / "transform").is_dir():
        REPO_ROOT = candidate


@dag(
    dag_id="backfill_market_bars",
    schedule=None,
    start_date=pendulum.datetime(2024, 1, 1, tz="America/New_York"),
    catchup=False,
    max_active_runs=1,
    # Fewer retries than daily: a mid-range failure should be restarted with
    # start_date at the failed date rather than re-walking the whole loop.
    default_args={
        "retries": 1,
        "retry_delay": timedelta(minutes=15),
    },
    params={
        "start_date": Param(
            type="string",
            description=(
                "Inclusive range start YYYY-MM-DD. Do not overlap a trade_date "
                "the daily DAG is currently processing."
            ),
        ),
        "end_date": Param(
            type="string",
            description=(
                "Inclusive range end YYYY-MM-DD. Do not overlap a trade_date "
                "the daily DAG is currently processing."
            ),
        ),
    },
    tags=["market", "backfill"],
)
def backfill_market_bars() -> None:
    @task
    def validate_range(*, params: dict) -> list[str]:
        dates = list(iter_trade_dates(params.get("start_date"), params.get("end_date")))
        return [d.isoformat() for d in dates]

    @task
    def backfill_dates(date_isos: list[str]) -> int:
        from extract.config import load_local_env
        from extract.daily_bars import main
        from load.copy_daily_bars import copy_daily_bars

        load_local_env()
        for iso in date_isos:
            main([iso])
            copy_daily_bars(date.fromisoformat(iso))
        return len(date_isos)

    @task
    def run_dbt(_loaded_count: int) -> None:
        transform_dir = REPO_ROOT / "transform"
        subprocess.run(
            ["dbt", "build", "--profiles-dir", "."],
            cwd=transform_dir,
            check=True,
        )

    run_dbt(backfill_dates(validate_range()))


backfill_market_bars()
