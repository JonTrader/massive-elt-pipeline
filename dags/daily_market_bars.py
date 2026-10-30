"""Daily extract -> load -> dbt for one US equity market date."""

from __future__ import annotations

import subprocess
from datetime import date, timedelta
from pathlib import Path

import pendulum
from airflow.sdk import Param, dag, task
from airflow.timetables.trigger import CronTriggerTimetable
from trade_dates import resolve_trade_date

REPO_ROOT = Path("/opt/airflow/repo")
if not (REPO_ROOT / "transform").is_dir():
    # Host / non-compose layout: dags/ sits next to extract/ and transform/.
    candidate = Path(__file__).resolve().parents[1]
    if (candidate / "extract").is_dir() and (candidate / "transform").is_dir():
        REPO_ROOT = candidate


@dag(
    dag_id="daily_market_bars",
    schedule=CronTriggerTimetable(
        "0 6 * * 2-6",
        timezone="America/New_York",
    ),
    start_date=pendulum.datetime(2024, 1, 1, tz="America/New_York"),
    catchup=False,
    max_active_runs=1,
    default_args={
        "retries": 3,
        "retry_delay": timedelta(minutes=30),
    },
    params={
        "trade_date": Param(
            default=None,
            type=["null", "string"],
            description=(
                "Market date YYYY-MM-DD. Empty uses America/New_York today minus "
                "one day (not Airflow logical_date)."
            ),
        ),
    },
    tags=["market", "daily"],
)
def daily_market_bars() -> None:
    @task
    def resolve_date(*, params: dict) -> str:
        trade_date = resolve_trade_date(params.get("trade_date"))
        return trade_date.isoformat()

    @task
    def extract_bars(trade_date_iso: str) -> str:
        from extract.daily_bars import main

        main([trade_date_iso])
        return trade_date_iso

    @task
    def load_bars(trade_date_iso: str) -> str:
        from extract.config import load_local_env
        from load.copy_daily_bars import copy_daily_bars

        load_local_env()
        copy_daily_bars(date.fromisoformat(trade_date_iso))
        return trade_date_iso

    @task
    def run_dbt(_trade_date_iso: str) -> None:
        transform_dir = REPO_ROOT / "transform"
        subprocess.run(
            ["dbt", "build", "--profiles-dir", "."],
            cwd=transform_dir,
            check=True,
        )

    trade_date_iso = resolve_date()
    run_dbt(load_bars(extract_bars(trade_date_iso)))


daily_market_bars()
