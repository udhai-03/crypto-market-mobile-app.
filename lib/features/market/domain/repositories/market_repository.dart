import 'package:crypto_market_mobile/features/market/domain/models/live_connection_status.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker_update.dart';

abstract interface class MarketRepository {
  /// Throws an `AppException` when market data cannot be loaded.
  Future<List<MarketTicker>> getMarketTickers();

  /// Live updates for the tracked pairs. Listening opens the live connection
  /// and cancelling the last subscription closes it. Connection problems are
  /// reported through [watchConnectionStatus], never as stream errors.
  Stream<MarketTickerUpdate> watchTickerUpdates();

  /// Emits the current live connection status, then every change.
  Stream<LiveConnectionStatus> watchConnectionStatus();
}
