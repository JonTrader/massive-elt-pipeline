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
- Gold (`MARTS`) is a star: `dim_date`, `dim_ticker`, and one fact `fact_daily_bar`. Derived session measures (dollar volume, range, gap, returns, open-to-high/low) are columns on that fact, not a second fact and not on a dim.
- `dollar_volume` is `close * volume`.
