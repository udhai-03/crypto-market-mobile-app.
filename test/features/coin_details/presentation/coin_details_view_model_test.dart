import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/models/chart_timeframe.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/models/price_candle.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/models/coin_ticker_state.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/models/price_chart_data.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/viewmodels/coin_details_view_model.dart';
import 'package:crypto_market_mobile/features/coin_details/providers/coin_details_providers.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_view_model.dart';
import 'package:crypto_market_mobile/features/market/providers/market_providers.dart';

import '../../../helpers/fake_chart_repository.dart';
import '../../../helpers/fake_market_repository.dart';

void main() {
  const symbol = 'ETHUSDT';

  late FakeMarketRepository marketRepository;
  late FakeChartRepository chartRepository;
  late ProviderContainer container;

  setUp(() {
    marketRepository = FakeMarketRepository([() => sampleTickers]);
    chartRepository = FakeChartRepository();
    container = ProviderContainer(
      overrides: [
        marketRepositoryProvider.overrideWithValue(marketRepository),
        chartRepositoryProvider.overrideWithValue(chartRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  ProviderSubscription<AsyncValue<PriceChartData>> watchChart([
    String chartSymbol = symbol,
  ]) {
    final subscription = container.listen(
      coinChartProvider(chartSymbol),
      (_, _) {},
    );
    addTearDown(subscription.close);
    return subscription;
  }

  CoinDetailsViewModel viewModel([String chartSymbol = symbol]) =>
      container.read(coinDetailsViewModelProvider(chartSymbol).notifier);

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('loads the initial 24H history for the selected symbol', () async {
    final chart = watchChart();
    expect(chart.read().isLoading, isTrue);

    await settle();

    expect(chartRepository.requests, [
      (symbol: symbol, timeframe: ChartTimeframe.oneDay),
    ]);
    expect(chart.read().value?.candles, hasLength(24));
    expect(chart.read().value?.timeframe, ChartTimeframe.oneDay);
  });

  test('changing the timeframe loads that history', () async {
    final chart = watchChart();
    await settle();

    viewModel().selectTimeframe(ChartTimeframe.sevenDays);
    expect(chart.read().isLoading, isTrue);
    await settle();

    expect(chartRepository.requests.last, (
      symbol: symbol,
      timeframe: ChartTimeframe.sevenDays,
    ));
    expect(chart.read().value?.timeframe, ChartTimeframe.sevenDays);
  });

  test('selecting the current timeframe does not refetch', () async {
    watchChart();
    await settle();

    viewModel().selectTimeframe(ChartTimeframe.oneDay);
    await settle();

    expect(chartRepository.requests, hasLength(1));
  });

  test('switching back to a recent timeframe reuses its history', () async {
    watchChart();
    await settle();

    viewModel().selectTimeframe(ChartTimeframe.oneHour);
    await settle();
    viewModel().selectTimeframe(ChartTimeframe.oneDay);
    await settle();

    expect(chartRepository.requests.map((request) => request.timeframe), [
      ChartTimeframe.oneDay,
      ChartTimeframe.oneHour,
    ]);
  });

  test(
    'a failed request can be retried without reloading the ticker',
    () async {
      var attempts = 0;
      chartRepository.responder = (_, _) {
        attempts++;
        if (attempts == 1) throw const NoConnectionException();
        return buildCandles();
      };
      final chart = watchChart();
      final ticker = container.listen(coinTickerProvider(symbol), (_, _) {});
      addTearDown(ticker.close);
      await settle();

      expect(chart.read().error, isA<NoConnectionException>());

      viewModel().retryChart();
      expect(chart.read().isLoading, isTrue);
      await settle();

      expect(chart.read().hasError, isFalse);
      expect(chart.read().value?.candles, hasLength(24));
      expect(marketRepository.callCount, 1);
      expect(ticker.read(), isA<CoinTickerAvailable>());
    },
  );

  test('an empty response is an empty chart, not an error', () async {
    chartRepository.responder = (_, _) => const [];
    final chart = watchChart();
    await settle();

    expect(chart.read().hasError, isFalse);
    expect(chart.read().value?.candles, isEmpty);
    expect(chart.read().value?.hasEnoughData, isFalse);
  });

  test(
    'a slow response for an old timeframe never replaces a newer one',
    () async {
      final pending = <ChartTimeframe, Completer<List<PriceCandle>>>{};
      chartRepository.responder = (_, timeframe) =>
          (pending[timeframe] = Completer()).future;
      final chart = watchChart();
      await settle();

      viewModel().selectTimeframe(ChartTimeframe.oneHour);
      await settle();
      viewModel().selectTimeframe(ChartTimeframe.sevenDays);
      await settle();

      pending[ChartTimeframe.sevenDays]!.complete(buildCandles(count: 7));
      await settle();
      pending[ChartTimeframe.oneHour]!.complete(buildCandles(count: 60));
      pending[ChartTimeframe.oneDay]!.complete(buildCandles(count: 96));
      await settle();

      expect(
        container.read(coinDetailsViewModelProvider(symbol)),
        ChartTimeframe.sevenDays,
      );
      expect(chart.read().value?.timeframe, ChartTimeframe.sevenDays);
      expect(chart.read().value?.candles, hasLength(7));
    },
  );

  test('each symbol keeps its own selection and history', () async {
    watchChart('BTCUSDT');
    watchChart('ADAUSDT');
    await settle();

    viewModel('ADAUSDT').selectTimeframe(ChartTimeframe.thirtyDays);
    await settle();

    expect(
      container.read(coinDetailsViewModelProvider('BTCUSDT')),
      ChartTimeframe.oneDay,
    );
    expect(chartRepository.requests, [
      (symbol: 'BTCUSDT', timeframe: ChartTimeframe.oneDay),
      (symbol: 'ADAUSDT', timeframe: ChartTimeframe.oneDay),
      (symbol: 'ADAUSDT', timeframe: ChartTimeframe.thirtyDays),
    ]);
  });

  group('ticker summary', () {
    test('is loading until the market snapshot arrives', () async {
      final ticker = container.listen(coinTickerProvider(symbol), (_, _) {});
      addTearDown(ticker.close);

      expect(ticker.read(), isA<CoinTickerLoading>());

      await container.read(marketViewModelProvider.future);

      final state = ticker.read();
      expect(state, isA<CoinTickerAvailable>());
      expect((state as CoinTickerAvailable).ticker.symbol, symbol);
    });

    test('is unavailable when the snapshot fails or lacks the pair', () async {
      final failing = ProviderContainer(
        overrides: [
          marketRepositoryProvider.overrideWithValue(
            FakeMarketRepository([() => throw const NoConnectionException()]),
          ),
        ],
      );
      addTearDown(failing.dispose);
      final ticker = failing.listen(coinTickerProvider(symbol), (_, _) {});
      addTearDown(ticker.close);
      await settle();

      expect(ticker.read(), isA<CoinTickerUnavailable>());

      final missing = container.listen(
        coinTickerProvider('LTCUSDT'),
        (_, _) {},
      );
      addTearDown(missing.close);
      await container.read(marketViewModelProvider.future);

      expect(missing.read(), isA<CoinTickerUnavailable>());
    });

    test('live updates change the summary without reloading candles', () async {
      final chart = watchChart();
      final ticker = container.listen(coinTickerProvider(symbol), (_, _) {});
      addTearDown(ticker.close);
      await container.read(marketViewModelProvider.future);
      await settle();
      viewModel().selectTimeframe(ChartTimeframe.fourHours);
      await settle();
      final candlesBefore = chart.read().value;

      marketRepository.emitUpdate(
        buildUpdate(
          symbol: symbol,
          lastPrice: 2600,
          priceChangePercent: 7.5,
          highPrice: 2650,
          quoteVolume: 5e8,
        ),
      );

      final updated = (ticker.read() as CoinTickerAvailable).ticker;
      expect(updated.lastPrice, 2600);
      expect(updated.priceChangePercent, 7.5);
      expect(updated.highPrice, 2650);
      expect(updated.quoteVolume, 5e8);
      expect(chartRepository.requests, hasLength(2));
      expect(identical(chart.read().value, candlesBefore), isTrue);
      expect(
        container.read(coinDetailsViewModelProvider(symbol)),
        ChartTimeframe.fourHours,
      );
    });

    test('ignores live updates for other symbols', () async {
      final ticker = container.listen(coinTickerProvider(symbol), (_, _) {});
      addTearDown(ticker.close);
      await container.read(marketViewModelProvider.future);
      final before = ticker.read();

      marketRepository.emitUpdate(buildUpdate(symbol: 'BTCUSDT'));

      expect(identical(ticker.read(), before), isTrue);
    });
  });
}
