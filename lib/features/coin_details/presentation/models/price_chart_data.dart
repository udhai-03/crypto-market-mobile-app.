import 'dart:math' as math;

import 'package:crypto_market_mobile/features/coin_details/domain/models/chart_timeframe.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/models/price_candle.dart';

/// Chart-ready view of historical candles, computed once per response.
class PriceChartData {
  PriceChartData._({
    required this.timeframe,
    required this.candles,
    required this.minPrice,
    required this.maxPrice,
    required this.lowPrice,
    required this.highPrice,
  });

  factory PriceChartData.fromCandles(
    List<PriceCandle> candles,
    ChartTimeframe timeframe,
  ) {
    var minClose = double.infinity;
    var maxClose = double.negativeInfinity;
    var low = double.infinity;
    var high = double.negativeInfinity;
    for (final candle in candles) {
      minClose = math.min(minClose, candle.close);
      maxClose = math.max(maxClose, candle.close);
      low = math.min(low, candle.low);
      high = math.max(high, candle.high);
    }
    final isEmpty = candles.isEmpty;
    return PriceChartData._(
      timeframe: timeframe,
      candles: candles,
      minPrice: isEmpty ? 0 : minClose,
      maxPrice: isEmpty ? 0 : maxClose,
      lowPrice: isEmpty ? 0 : low,
      highPrice: isEmpty ? 0 : high,
    );
  }

  /// A line needs at least two points.
  static const minimumCandles = 2;

  final ChartTimeframe timeframe;

  /// Oldest first.
  final List<PriceCandle> candles;

  /// Lowest and highest closing price, i.e. the plotted range.
  final double minPrice;
  final double maxPrice;

  /// Lowest low and highest high traded within the window.
  final double lowPrice;
  final double highPrice;

  bool get hasEnoughData => candles.length >= minimumCandles;

  PriceCandle get first => candles.first;
  PriceCandle get last => candles.last;

  /// Percentage change from the window's first open to [candle]'s close.
  double changePercentAt(PriceCandle candle) {
    final open = first.open;
    return open == 0 ? 0 : (candle.close - open) / open * 100;
  }
}
