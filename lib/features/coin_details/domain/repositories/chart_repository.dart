import 'package:crypto_market_mobile/features/coin_details/domain/models/chart_timeframe.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/models/price_candle.dart';

abstract interface class ChartRepository {
  /// Historical candles for [symbol] covering [timeframe], oldest first.
  /// May contain fewer candles than the window implies (e.g. new listings).
  ///
  /// Throws an `AppException` when the history cannot be loaded.
  Future<List<PriceCandle>> getCandles({
    required String symbol,
    required ChartTimeframe timeframe,
  });
}
