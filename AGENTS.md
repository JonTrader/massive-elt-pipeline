# Agent notes

Daily US equity bars: one Massive grouped request per market date lands as Parquet plus a manifest on S3, Snowflake loads it into `MARKET.RAW`, dbt builds `STAGING` and `MARTS`, and local Airflow runs extract, load, then `dbt build`.

## Commands

Python 3.14 with pip in one repo-root `.venv` (`.venv\Scripts\python.exe` on Windows, `.venv/bin/python` elsewhere). No uv, Poetry, or `pip install .`.

```text
python -m pip install -r requirements.txt
python -m pip install --group dev
python -m ruff check
python -m ruff format --check
python -m pytest
```

dbt runs from `transform/` and always needs `--profiles-dir .`:

```text
dbt deps --profiles-dir .
dbt build --profiles-dir .
```

## Always

- Do not read `.env`. It holds secrets.
- There is no `src/`, `lib/`, or `utils/`. Search `extract/`, `load/`, `dags/`, and `transform/` before adding a function.

## Topic guides

Read the guide that matches the task:

- [Repository layout and docs policy](docs/agents/repository.md) - what each folder does, where README and these guides fit, and when to update them
- [Python environment and dependencies](docs/agents/dependencies.md) - venv, pin locations, dbt packages
- [Pipeline contracts](docs/agents/pipeline-contracts.md) - extract, load, and dbt rules that code must not weaken
- [Code style](docs/agents/code-style.md)
- [Testing](docs/agents/testing.md)
- [Security and secrets](docs/agents/security.md)
- [Local Airflow](docs/agents/airflow-local.md) - Docker image, compose mounts, key mount
