import 'dart:async';

import 'package:crypto_market_mobile/features/coin_details/domain/models/chart_timeframe.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/models/price_candle.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/repositories/chart_repository.dart';

typedef CandleResponder = FutureOr<List<PriceCandle>> Function(
  String symbol,
  ChartTimeframe timeframe,
);

/// Records every request and answers with [responder] (default: 24 rising
/// candles).
class FakeChartRepository implements ChartRepository {
  FakeChartRepository([CandleResponder? responder])
    : responder = responder ?? ((_, _) => buildCandles());

  CandleResponder responder;
  final requests = <({String symbol, ChartTimeframe timeframe})>[];

  @override
  Future<List<PriceCandle>> getCandles({
    required String symbol,
    required ChartTimeframe timeframe,
  }) async {
    requests.add((symbol: symbol, timeframe: timeframe));
    return responder(symbol, timeframe);
  }
}

final candleStart = DateTime.utc(2026, 10, 9, 8);

/// [count] consecutive candles of [step], closing [priceStep] higher each.
List<PriceCandle> buildCandles({
  int count = 24,
  double startPrice = 100,
  double priceStep = 1,
  Duration step = const Duration(minutes: 15),
}) {
  return [
    for (var i = 0; i < count; i++)
      PriceCandle(
        openTime: candleStart.add(step * i),
        closeTime: candleStart
            .add(step * (i + 1))
            .subtract(const Duration(milliseconds: 1)),
        open: startPrice + priceStep * i,
        high: startPrice + priceStep * i + priceStep * 2,
        low: startPrice + priceStep * i - priceStep,
        close: startPrice + priceStep * (i + 1),
        volume: 10,
        quoteVolume: 1000,
      ),
  ];
}
