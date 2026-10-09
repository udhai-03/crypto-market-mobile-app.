import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';

/// Statistics derived from the tracked Binance pairs only, not the global
/// crypto market.
class MarketSummary {
  const MarketSummary({
    required this.trackedCount,
    required this.gainersCount,
    required this.losersCount,
    required this.averageChangePercent,
    this.topVolumeTicker,
  });

  factory MarketSummary.fromTickers(List<MarketTicker> tickers) {
    if (tickers.isEmpty) return empty;

    var gainers = 0;
    var losers = 0;
    var changeSum = 0.0;
    var topVolume = tickers.first;

    for (final ticker in tickers) {
      if (ticker.priceChangePercent > 0) {
        gainers++;
      } else if (ticker.priceChangePercent < 0) {
        losers++;
      }
      changeSum += ticker.priceChangePercent;
      if (ticker.quoteVolume > topVolume.quoteVolume) topVolume = ticker;
    }

    return MarketSummary(
      trackedCount: tickers.length,
      gainersCount: gainers,
      losersCount: losers,
      averageChangePercent: changeSum / tickers.length,
      topVolumeTicker: topVolume,
    );
  }

  static const empty = MarketSummary(
    trackedCount: 0,
    gainersCount: 0,
    losersCount: 0,
    averageChangePercent: 0,
  );

  final int trackedCount;
  final int gainersCount;
  final int losersCount;

  /// Unweighted mean of the 24h percentage change of each tracked pair.
  final double averageChangePercent;

  /// Pair with the highest 24h volume in its quote asset (USDT).
  final MarketTicker? topVolumeTicker;
}
