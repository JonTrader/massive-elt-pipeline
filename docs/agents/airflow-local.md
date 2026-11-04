# Local Airflow

- Requires Docker Desktop. Image tag `massive-etl-airflow:3.3.2-python3.14`, built from `Dockerfile` and run with the root `docker-compose.yaml`.
- From the repo root: `docker compose build`, then `docker compose up -d`. UI at `http://localhost:8080`.
- Compose mounts the repo at `/opt/airflow/repo` and sets `PYTHONPATH` so `import extract` and `import load` work. It reads `env_file: .env`.
- DAGs call the same extract, load, and `dbt build` as the CLI.
- Do not add a second venv inside the image or relax runtime pins to fit Airflow constraints.

## Snowflake key

- Put the key at host `secrets/snowflake.p8`. The `secrets/` directory and `*.p8` are gitignored.
- Compose bind-mounts it read-only to `/opt/airflow/secrets/snowflake.p8` and overrides `SNOWFLAKE_PRIVATE_KEY_PATH` to that container path.
- Optional non-secret `AIRFLOW_UID=50000` in `.env` silences a compose warning on Windows.
