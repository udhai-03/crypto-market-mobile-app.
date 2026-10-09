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
    this.topGainer,
    this.topLoser,
  });

  factory MarketSummary.fromTickers(List<MarketTicker> tickers) {
    if (tickers.isEmpty) return empty;

    var gainers = 0;
    var losers = 0;
    var changeSum = 0.0;
    var topVolume = tickers.first;
    MarketTicker? topGainer;
    MarketTicker? topLoser;

    for (final ticker in tickers) {
      final change = ticker.priceChangePercent;
      if (change > 0) {
        gainers++;
        if (topGainer == null || change > topGainer.priceChangePercent) {
          topGainer = ticker;
        }
      } else if (change < 0) {
        losers++;
        if (topLoser == null || change < topLoser.priceChangePercent) {
          topLoser = ticker;
        }
      }
      changeSum += change;
      if (ticker.quoteVolume > topVolume.quoteVolume) topVolume = ticker;
    }

    return MarketSummary(
      trackedCount: tickers.length,
      gainersCount: gainers,
      losersCount: losers,
      averageChangePercent: changeSum / tickers.length,
      topVolumeTicker: topVolume,
      topGainer: topGainer,
      topLoser: topLoser,
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

  /// Pair with the largest 24h rise; null when nothing rose.
  final MarketTicker? topGainer;

  /// Pair with the largest 24h fall; null when nothing fell.
  final MarketTicker? topLoser;
}
