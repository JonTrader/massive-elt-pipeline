# Testing

- pytest never opens a live S3 bucket, the Massive API, or a Snowflake account.
- Extract landing changes: add coverage in `tests/test_daily_bars.py`. Stub HTTP with `responses` and S3 with moto.
- Load changes: add coverage in `tests/test_copy_daily_bars.py`. Mock S3 with moto and mock `snowflake.connector.connect`.
- Trade-date resolution for the DAGs is covered in `tests/test_trade_dates.py`.
- Prefer tests that lock contracts (manifest checks, delete-then-copy shape, zero-row `COPY`, session parameters, dbt source and staging contracts) over tests of internal structure.
- dbt: `dbt parse --profiles-dir .` checks the project without a connection; `dbt build --profiles-dir .` runs models and data tests against Snowflake.
