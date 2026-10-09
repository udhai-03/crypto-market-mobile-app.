import 'package:crypto_market_mobile/features/market/domain/models/market_ticker_update.dart';

/// 24-hour market snapshot for a single trading pair.
class MarketTicker {
  const MarketTicker({
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

  /// Traded amount in the base asset, e.g. BTC for BTCUSDT.
  final double volume;

  /// Traded amount in the quote asset, e.g. USDT for BTCUSDT.
  final double quoteVolume;

  /// When these statistics were computed (UTC), used to keep the newest
  /// values when a snapshot and live updates overlap.
  final DateTime updatedAt;

  /// Returns a copy with the live statistics from [update]; identity fields
  /// such as [symbol] are kept from this snapshot.
  MarketTicker applyUpdate(MarketTickerUpdate update) {
    assert(update.symbol == symbol);
    return MarketTicker(
      symbol: symbol,
      lastPrice: update.lastPrice,
      priceChange: update.priceChange,
      priceChangePercent: update.priceChangePercent,
      highPrice: update.highPrice,
      lowPrice: update.lowPrice,
      volume: update.volume,
      quoteVolume: update.quoteVolume,
      updatedAt: update.updatedAt,
    );
  }
}
