-- Quoted vendor names on the way out. A dict fixture would emit unquoted
-- T and t, and Snowflake would fold both to T.
select
    cast(ticker as varchar) as "T",
    cast(open_px as float) as "o",
    cast(high_px as float) as "h",
    cast(low_px as float) as "l",
    cast(close_px as float) as "c",
    cast(volume_sh as float) as "v",
    cast(vwap_px as float) as "vw",
    cast(window_ms as number) as "t",
    cast(txn_count as number) as "n",
    to_date(trade_date_text) as trade_date,
    to_timestamp_ntz(extracted_at_text) as extracted_at
from (
    values
        -- ticker, open, high, low, close, volume, vwap, window_ms, transactions, trade_date, extracted_at
        ('AAPL', 8, 16, 4, 16, 100, 10.5, 1001, 40, '2024-01-02', '2024-01-02 21:00:00'),
        (null, 8, 10, 6, 9, 10, 8, 1002, 1, '2024-01-03', '2024-01-02 21:00:00'),
        ('NULL_O', null, 10, 6, 9, 10, 8, 1003, 2, '2024-01-04', '2024-01-02 21:00:00'),
        ('NULL_H', 8, null, 6, 9, 10, 8, 1004, 3, '2024-01-05', '2024-01-02 21:00:00'),
        ('NULL_L', 8, 10, null, 9, 10, 8, 1005, 4, '2024-01-08', '2024-01-02 21:00:00'),
        ('NULL_C', 8, 10, 6, null, 10, 8, 1006, 5, '2024-01-09', '2024-01-02 21:00:00'),
        ('NULL_V', 8, 10, 6, 9, null, 8, 1007, 6, '2024-01-10', '2024-01-02 21:00:00'),
        ('BAD_HL', 8, 5, 9, 7, 10, 8, 1008, 7, '2024-01-11', '2024-01-02 21:00:00'),
        ('NEG_V', 8, 10, 6, 9, -1, 8, 1009, 8, '2024-01-12', '2024-01-02 21:00:00')
) as raw_rows (
    ticker,
    open_px,
    high_px,
    low_px,
    close_px,
    volume_sh,
    vwap_px,
    window_ms,
    txn_count,
    trade_date_text,
    extracted_at_text
)
