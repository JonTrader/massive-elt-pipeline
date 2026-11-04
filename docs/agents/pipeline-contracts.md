# Pipeline contracts

Code must not weaken these.

## Extract and load

- One grouped Massive request per market date. Never call the API once per ticker.
- Cleansing belongs in SQL. The extract and the loader drop no rows and rename no vendor columns; names stay as landed until staging.
- Call `load_local_env()` once at the start of `main`, before any getter.
- Database, schema, tables, stage, file format, and the S3 prefix `bronze/daily_bars` stay hard-coded where the code already hard-codes them.

## dbt

- Do not dedupe silver by `extracted_at`. Delete-then-copy leaves one landing per date; uniqueness tests catch a broken load.
- `generate_schema_name` returns the custom schema as-is, so `STAGING` and `MARTS` are not concatenated onto the target schema.
- Gold (`MARTS`) is a star: `dim_date`, `dim_ticker`, `fact_daily_bar`, and `fact_daily_bar_performance`. Performance is a second fact at the same grain, linked only through the shared dims; it is not a dim and not a bridge table.
- `dollar_volume` is `close * volume`.
