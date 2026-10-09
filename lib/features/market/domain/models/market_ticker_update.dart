/// Live 24h statistics for one symbol, applied on top of a loaded
/// [MarketTicker] snapshot.
class MarketTickerUpdate {
  const MarketTickerUpdate({
    required this.symbol,
    required this.lastPrice,
    required this.priceChange,
    required this.priceChangePercent,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.quoteVolume,
    required this.updatedAt,
  });

  final String symbol;
  final double lastPrice;
  final double priceChange;
  final double priceChangePercent;
  final double highPrice;
  final double lowPrice;
  final double volume;
  final double quoteVolume;

  /// When these statistics were computed (UTC).
  final DateTime updatedAt;
}
