# Python environment and dependencies

## Environment

- One `.venv` at the repo root per checkout. Create it if it is missing; never create a second one or use system Python.
- CI installs into the runner's Python with the same two commands and no venv.
- Do not add uv, a lock file, a `[project]` table, or a `[build-system]`. Do not `pip install .` or `-e .`.
- The interpreter is Python 3.14 (`target-version` in `pyproject.toml`).

## Where pins live

| What | File | Install |
| --- | --- | --- |
| Runtime, exact `==` pins | `requirements.txt` | `python -m pip install -r requirements.txt` |
| Dev tools (pytest, responses, moto[s3], Ruff) | `[dependency-groups] dev` in `pyproject.toml` | `python -m pip install --group dev` |
| dbt packages (`dbt_utils`) | `transform/packages.yml` | `dbt deps --profiles-dir .` from `transform/` |

- The dev group does not include runtime, so run both pip installs.
- There is no `requirements-dev.txt`.
- `dbt-core` and `dbt-snowflake` are pinned on 1.12.x so pip does not pull a 1.13 beta.
- Do not add the `massive` package.
