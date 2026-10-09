import 'package:crypto_market_mobile/features/coin_details/domain/models/chart_timeframe.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/models/price_candle.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/repositories/chart_repository.dart';
import 'package:crypto_market_mobile/features/market/data/datasources/binance_remote_data_source.dart';

/// Binance kline interval and candle count for a chart timeframe.
typedef BinanceKlineRequest = ({String interval, int limit});

class BinanceChartRepository implements ChartRepository {
  const BinanceChartRepository(this._remoteDataSource);

  final BinanceRemoteDataSource _remoteDataSource;

  /// Each request covers the whole [ChartTimeframe.window]:
  /// 60 x 1m = 1h, 48 x 5m = 4h, 96 x 15m = 24h, 168 x 1h = 7d,
  /// 180 x 4h = 30d.
  static BinanceKlineRequest requestFor(ChartTimeframe timeframe) {
    return switch (timeframe) {
      ChartTimeframe.oneHour => (interval: '1m', limit: 60),
      ChartTimeframe.fourHours => (interval: '5m', limit: 48),
      ChartTimeframe.oneDay => (interval: '15m', limit: 96),
      ChartTimeframe.sevenDays => (interval: '1h', limit: 168),
      ChartTimeframe.thirtyDays => (interval: '4h', limit: 180),
    };
  }

  @override
  Future<List<PriceCandle>> getCandles({
    required String symbol,
    required ChartTimeframe timeframe,
  }) async {
    final request = requestFor(timeframe);
    final klines = await _remoteDataSource.fetchKlines(
      symbol: symbol,
      interval: request.interval,
      limit: request.limit,
    );

    final candles = [
      for (final kline in klines)
        PriceCandle(
          openTime: kline.openTime,
          closeTime: kline.closeTime,
          open: kline.open,
          high: kline.high,
          low: kline.low,
          close: kline.close,
          volume: kline.volume,
          quoteVolume: kline.quoteVolume,
        ),
    ]..sort((a, b) => a.openTime.compareTo(b.openTime));
    return List.unmodifiable(candles);
  }
}
