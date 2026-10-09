import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/features/coin_details/domain/models/chart_timeframe.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/models/price_candle.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/models/coin_ticker_state.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/models/price_chart_data.dart';
import 'package:crypto_market_mobile/features/coin_details/providers/coin_details_providers.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_view_model.dart';

/// Selected chart timeframe for one Coin Details screen, keyed by symbol.
final coinDetailsViewModelProvider = NotifierProvider.autoDispose
    .family<CoinDetailsViewModel, ChartTimeframe, String>(
      CoinDetailsViewModel.new,
    );

class CoinDetailsViewModel extends Notifier<ChartTimeframe> {
  CoinDetailsViewModel(this.symbol);

  final String symbol;

  @override
  ChartTimeframe build() => ChartTimeframe.initial;

  void selectTimeframe(ChartTimeframe timeframe) {
    if (timeframe != state) state = timeframe;
  }

  /// Reloads only the chart for the current timeframe.
  void retryChart() {
    ref.invalidate(coinCandlesProvider((symbol: symbol, timeframe: state)));
  }
}

typedef CandleRequest = ({String symbol, ChartTimeframe timeframe});

/// Minimum time a requested history stays cached, so switching back to a
/// recent timeframe does not refetch immediately. Afterwards it is disposed
/// once nothing watches it.
const candleCacheDuration = Duration(minutes: 1);

/// One provider per symbol and timeframe: a slow response for an older
/// selection can only update its own entry, never the current chart.
final coinCandlesProvider = FutureProvider.autoDispose
    .family<List<PriceCandle>, CandleRequest>((ref, request) {
      final keepAlive = ref.keepAlive();
      final cacheTimer = Timer(candleCacheDuration, keepAlive.close);
      ref.onDispose(cacheTimer.cancel);

      return ref
          .watch(chartRepositoryProvider)
          .getCandles(symbol: request.symbol, timeframe: request.timeframe);
    }, retry: _retryOnlyOnUserRequest);

Duration? _retryOnlyOnUserRequest(int retryCount, Object error) => null;

/// Chart state for the currently selected timeframe of [symbol].
final coinChartProvider = Provider.autoDispose
    .family<AsyncValue<PriceChartData>, String>((ref, symbol) {
      final timeframe = ref.watch(coinDetailsViewModelProvider(symbol));
      final candles = ref.watch(
        coinCandlesProvider((symbol: symbol, timeframe: timeframe)),
      );
      return candles.whenData(
        (candles) => PriceChartData.fromCandles(candles, timeframe),
      );
    });

/// The selected pair's ticker from the shared market state, which merges
/// the REST snapshot with live WebSocket updates.
final coinTickerProvider = Provider.autoDispose.family<CoinTickerState, String>(
  (ref, symbol) {
    final ticker = ref.watch(
      marketViewModelProvider.select(
        (state) => _tickerFor(state.value, symbol),
      ),
    );
    if (ticker != null) return CoinTickerAvailable(ticker);

    final isLoading = ref.watch(
      marketViewModelProvider.select((state) => state.isLoading),
    );
    return isLoading
        ? const CoinTickerLoading()
        : const CoinTickerUnavailable();
  },
);

MarketTicker? _tickerFor(List<MarketTicker>? tickers, String symbol) {
  if (tickers == null) return null;
  for (final ticker in tickers) {
    if (ticker.symbol == symbol) return ticker;
  }
  return null;
}
