import 'dart:async';

import 'package:crypto_market_mobile/features/market/domain/models/live_connection_status.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker_update.dart';
import 'package:crypto_market_mobile/features/market/domain/repositories/market_repository.dart';

/// Returns queued responses in order; each call takes the next one.
/// Live updates and connection statuses are pushed manually by tests.
class FakeMarketRepository implements MarketRepository {
  FakeMarketRepository(this._responses);

  final List<FutureOr<List<MarketTicker>> Function()> _responses;
  int callCount = 0;

  final _tickerUpdates = StreamController<MarketTickerUpdate>.broadcast(
    sync: true,
  );
  final _statusChanges = StreamController<LiveConnectionStatus>.broadcast(
    sync: true,
  );
  LiveConnectionStatus connectionStatus = LiveConnectionStatus.connecting;

  bool get hasLiveListener => _tickerUpdates.hasListener;

  void emitUpdate(MarketTickerUpdate update) => _tickerUpdates.add(update);

  void emitStatus(LiveConnectionStatus status) {
    connectionStatus = status;
    _statusChanges.add(status);
  }

  @override
  Future<List<MarketTicker>> getMarketTickers() async {
    final response = _responses[callCount];
    callCount++;
    return response();
  }

  @override
  Stream<MarketTickerUpdate> watchTickerUpdates() => _tickerUpdates.stream;

  @override
  Stream<LiveConnectionStatus> watchConnectionStatus() {
    return Stream.multi((controller) {
      controller.addSync(connectionStatus);
      final subscription = _statusChanges.stream.listen(controller.addSync);
      controller.onCancel = subscription.cancel;
    });
  }
}

/// Statistics time of [buildTicker] snapshots; [buildUpdate] defaults to
/// one second later so updates are newer than snapshots unless a test
/// says otherwise.
final snapshotTime = DateTime.utc(2026, 10, 9, 10);
final liveUpdateTime = snapshotTime.add(const Duration(seconds: 1));

MarketTicker buildTicker({
  String symbol = 'BTCUSDT',
  double lastPrice = 100,
  double priceChangePercent = 1.5,
  double quoteVolume = 1000,
  DateTime? updatedAt,
}) {
  return MarketTicker(
    symbol: symbol,
    lastPrice: lastPrice,
    priceChange: 1,
    priceChangePercent: priceChangePercent,
    highPrice: lastPrice,
    lowPrice: lastPrice,
    volume: 10,
    quoteVolume: quoteVolume,
    updatedAt: updatedAt ?? snapshotTime,
  );
}

MarketTickerUpdate buildUpdate({
  DateTime? updatedAt,
  String symbol = 'BTCUSDT',
  double lastPrice = 200,
  double priceChange = 5,
  double priceChangePercent = 2.5,
  double highPrice = 210,
  double lowPrice = 190,
  double volume = 20,
  double quoteVolume = 4000,
}) {
  return MarketTickerUpdate(
    symbol: symbol,
    lastPrice: lastPrice,
    priceChange: priceChange,
    priceChangePercent: priceChangePercent,
    highPrice: highPrice,
    lowPrice: lowPrice,
    volume: volume,
    quoteVolume: quoteVolume,
    updatedAt: updatedAt ?? liveUpdateTime,
  );
}

/// Mixed gainers, losers, and an unchanged pair with distinct values.
final sampleTickers = [
  buildTicker(
    symbol: 'BTCUSDT',
    lastPrice: 80600.01,
    priceChangePercent: -3.3,
    quoteVolume: 1.71e9,
  ),
  buildTicker(
    symbol: 'ETHUSDT',
    lastPrice: 2414.46,
    priceChangePercent: 2.1,
    quoteVolume: 9.75e8,
  ),
  buildTicker(
    symbol: 'BNBUSDT',
    lastPrice: 721.06,
    priceChangePercent: -6.4,
    quoteVolume: 1.28e8,
  ),
  buildTicker(
    symbol: 'ADAUSDT',
    lastPrice: 0.2249,
    priceChangePercent: 4.8,
    quoteVolume: 6.08e7,
  ),
  buildTicker(
    symbol: 'TRXUSDT',
    lastPrice: 0.3328,
    priceChangePercent: 0,
    quoteVolume: 3.23e7,
  ),
];
