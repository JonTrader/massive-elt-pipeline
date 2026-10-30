"""Placeholder DAG so the local UI shows a parseable DAG. No extract/load/dbt."""

from __future__ import annotations

from datetime import datetime

from airflow.sdk import dag, task


@dag(
    dag_id="stack_health",
    schedule=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["health"],
)
def stack_health() -> None:
    @task
    def ping() -> str:
        return "ok"

    ping()


stack_health()
