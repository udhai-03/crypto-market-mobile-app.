/// A Binance kline array in the documented 12-field layout; defaults are a
/// real BTCUSDT 1h candle opening at 2026-10-09 09:00 UTC.
List<Object?> klineRecord({
  Object? openTime = 1791536400000,
  Object? open = '82704.00000000',
  Object? high = '82704.01000000',
  Object? low = '82550.00000000',
  Object? close = '82658.01000000',
  Object? volume = '283.97863000',
  Object? closeTime = 1791539999999,
  Object? quoteVolume = '23462671.97230810',
}) {
  return [
    openTime,
    open,
    high,
    low,
    close,
    volume,
    closeTime,
    quoteVolume,
    47315,
    '166.68702000',
    '13772108.91734340',
    '0',
  ];
}
