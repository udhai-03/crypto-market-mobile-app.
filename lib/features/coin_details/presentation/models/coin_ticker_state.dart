import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';

/// Availability of the selected pair's 24h ticker on the Coin Details screen.
sealed class CoinTickerState {
  const CoinTickerState();
}

/// The market snapshot is still loading and no ticker is known yet.
final class CoinTickerLoading extends CoinTickerState {
  const CoinTickerLoading();
}

/// Last known ticker; kept current by live updates while connected.
final class CoinTickerAvailable extends CoinTickerState {
  const CoinTickerAvailable(this.ticker);

  final MarketTicker ticker;
}

/// The market snapshot failed to load or does not contain this pair.
final class CoinTickerUnavailable extends CoinTickerState {
  const CoinTickerUnavailable();
}
