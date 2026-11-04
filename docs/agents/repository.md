# Repository layout and docs policy

## Layout

| Path | Role |
| --- | --- |
| `extract/` | Land one date on S3 (`python -m extract.daily_bars YYYY-MM-DD`) |
| `load/` | Reload one date into Snowflake (`python -m load.copy_daily_bars YYYY-MM-DD`) |
| `transform/` | dbt project `market_bars`; run from here with `--profiles-dir .` |
| `dags/` | Airflow TaskFlow DAGs (daily and backfill); call the same extract, load, and dbt as the CLI |
| `snowflake/` | Bootstrap SQL |
| `tests/` | pytest |
| `docs/agents/` | Agent guides linked from `AGENTS.md` |

`extract/__init__.py` is empty; keep it empty. Do not add `load/__init__.py` or other package inits.

## Where things are written down

- `README.md` is the system description: grain, architecture, design decisions. It is not a changelog, tutorial, or tool glossary.
- `AGENTS.md` and `docs/agents/` hold engineering contracts for agents.

## When to update

- A durable decision, layout, command, style, test, or security rule changes: update `AGENTS.md` or the matching guide here. This overrides any general instruction to update `AGENTS.md` after every task.
- The system description changes (grain, architecture, design decisions, status): update `README.md`.
