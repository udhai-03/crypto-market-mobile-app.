/// One historical price candle (OHLC) for a trading pair.
class PriceCandle {
  const PriceCandle({
    required this.openTime,
    required this.closeTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.quoteVolume,
  });

  /// UTC start of the candle.
  final DateTime openTime;

  /// UTC end of the candle (inclusive).
  final DateTime closeTime;

  final double open;
  final double high;
  final double low;
  final double close;

  /// Traded amount in the base asset, e.g. BTC for BTCUSDT.
  final double volume;

  /// Traded amount in the quote asset, e.g. USDT for BTCUSDT.
  final double quoteVolume;
}
