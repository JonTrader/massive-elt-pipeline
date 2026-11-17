-- Daily bar facts at grain ticker + trade_date.
-- Unadjusted OHLCV, VWAP, transaction count, and derived session measures.
-- window_start_epoch_ms stays in staging only; not a gold measure.
-- dollar_volume uses close * volume (locked). Prior-close fields are null on a
-- ticker's first day in the loaded history.

with bars as (
    select
        ticker,
        trade_date,
        open,
        high,
        low,
        close,
        volume,
        vwap,
        transactions,
        extracted_at,
        lag(close) over (
            partition by ticker
            order by trade_date
        ) as prior_close
    from {{ ref('stg_daily_bars') }}
)

select
    ticker,
    trade_date,
    open,
    high,
    low,
    close,
    volume,
    vwap,
    transactions,
    close * volume as dollar_volume,
    high - low as range,
    (open - prior_close) / nullif(prior_close, 0) as gap_pct,
    (close - prior_close) / nullif(prior_close, 0) as pct_gain_loss,
    (close - open) / nullif(open, 0) as pct_from_open,
    close - prior_close as dollar_change,
    close - open as dollar_change_from_open,
    (high - open) / nullif(open, 0) as pct_open_to_high,
    (low - open) / nullif(open, 0) as pct_open_to_low,
    extracted_at
from bars
