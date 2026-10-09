import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/app/app.dart';
import 'package:crypto_market_mobile/app/router/app_router.dart';
import 'package:crypto_market_mobile/core/constants/app_routes.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/core/widgets/skeleton_box.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/models/chart_timeframe.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/models/price_candle.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/views/coin_details_screen.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/widgets/coin_market_stats.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/widgets/coin_price_summary.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/widgets/price_history_chart.dart';
import 'package:crypto_market_mobile/features/coin_details/providers/coin_details_providers.dart';
import 'package:crypto_market_mobile/features/market/domain/models/live_connection_status.dart';
import 'package:crypto_market_mobile/features/market/presentation/views/market_screen.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_ticker_tile.dart';
import 'package:crypto_market_mobile/features/market/providers/market_providers.dart';
import 'package:crypto_market_mobile/features/watchlist/providers/watchlist_providers.dart';

import '../../../helpers/fake_chart_repository.dart';
import '../../../helpers/fake_market_repository.dart';
import '../../../helpers/fake_watchlist_storage.dart';

void main() {
  const tallPhoneSize = Size(412, 1600);

  late FakeMarketRepository marketRepository;
  late FakeChartRepository chartRepository;
  late FakeWatchlistStorage watchlistStorage;
  late ProviderContainer container;

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.single;
    view
      ..physicalSize = tallPhoneSize
      ..devicePixelRatio = 1;
    marketRepository = FakeMarketRepository([() => sampleTickers]);
    chartRepository = FakeChartRepository();
    watchlistStorage = FakeWatchlistStorage();
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.single.reset();
  });

  Finder summaryText(String text) => find.descendant(
    of: find.byType(CoinPriceSummary),
    matching: find.text(text),
  );

  /// The scope owns its container, so cached chart providers (and their
  /// cache timers) are disposed together with the widget tree.
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketRepositoryProvider.overrideWithValue(marketRepository),
          chartRepositoryProvider.overrideWithValue(chartRepository),
          watchlistStorageProvider.overrideWithValue(watchlistStorage),
        ],
        child: const CryptoMarketApp(),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(CryptoMarketApp)),
    );
  }

  Future<void> openDetails(WidgetTester tester, String symbol) async {
    await pumpApp(tester);
    container
        .read(appRouterProvider)
        .push(AppRoutes.coinDetailsLocation(symbol));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping a market row opens details for that pair', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.widgetWithText(MarketTickerTile, 'ETHUSDT'));
    await tester.pumpAndSettle();

    expect(find.byType(CoinDetailsScreen), findsOneWidget);
    expect(find.text('ETH / USDT'), findsOneWidget);
    expect(summaryText(r'$2,414.46'), findsOneWidget);
    expect(chartRepository.requests, [
      (symbol: 'ETHUSDT', timeframe: ChartTimeframe.oneDay),
    ]);

    await tester.tap(find.byTooltip(AppStrings.backTooltip));
    await tester.pumpAndSettle();

    expect(find.byType(MarketScreen), findsOneWidget);
    expect(find.byType(CoinDetailsScreen), findsNothing);
  });

  testWidgets('shows price, 24h change, chart and statistics', (tester) async {
    await openDetails(tester, 'BTCUSDT');

    expect(find.text('BTC / USDT'), findsOneWidget);
    expect(summaryText(r'$80,600.01'), findsOneWidget);
    expect(summaryText('-3.30%'), findsOneWidget);
    expect(find.byType(PriceHistoryChart), findsOneWidget);
    expect(find.text(AppStrings.chartHistoricalNote), findsOneWidget);
    expect(find.text(AppStrings.chartRangeCaption('24H')), findsOneWidget);
    expect(find.text(r'$124.00'), findsOneWidget);

    final stats = find.byType(CoinMarketStats);
    for (final label in [
      AppStrings.statHigh24h,
      AppStrings.statLow24h,
      AppStrings.statChange24h,
      AppStrings.volumeIn('BTC'),
      AppStrings.volumeIn('USDT'),
    ]) {
      expect(
        find.descendant(of: stats, matching: find.text(label)),
        findsOneWidget,
      );
    }
    expect(
      find.descendant(of: stats, matching: find.text('1.71B')),
      findsOneWidget,
    );
  });

  testWidgets('selecting a timeframe loads its history', (tester) async {
    await openDetails(tester, 'SOLUSDT');

    await tester.tap(find.text(AppStrings.timeframeSevenDays));
    await tester.pumpAndSettle();

    expect(chartRepository.requests.last, (
      symbol: 'SOLUSDT',
      timeframe: ChartTimeframe.sevenDays,
    ));
    expect(find.text(AppStrings.chartRangeCaption('7D')), findsOneWidget);
  });

  testWidgets('shows a chart loading state while history loads', (
    tester,
  ) async {
    final response = Completer<List<PriceCandle>>();
    chartRepository.responder = (_, _) => response.future;
    await openDetails(tester, 'BTCUSDT');

    expect(find.byType(SkeletonBox), findsOneWidget);
    expect(find.byType(PriceHistoryChart), findsNothing);
    expect(summaryText(r'$80,600.01'), findsOneWidget);

    response.complete(buildCandles());
    await tester.pumpAndSettle();

    expect(find.byType(SkeletonBox), findsNothing);
    expect(find.byType(PriceHistoryChart), findsOneWidget);
  });

  testWidgets('chart errors keep the price visible and can be retried', (
    tester,
  ) async {
    var attempts = 0;
    chartRepository.responder = (_, _) {
      attempts++;
      if (attempts == 1) throw const RequestTimeoutException();
      return buildCandles();
    };
    await openDetails(tester, 'BTCUSDT');

    expect(find.text(AppStrings.chartErrorTitle), findsOneWidget);
    expect(find.text(AppStrings.timeoutError), findsOneWidget);
    expect(summaryText(r'$80,600.01'), findsOneWidget);
    expect(find.byType(CoinMarketStats), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, AppStrings.retry));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.chartErrorTitle), findsNothing);
    expect(find.byType(PriceHistoryChart), findsOneWidget);
    expect(marketRepository.callCount, 1);
  });

  testWidgets('shows an empty state when there is no history', (tester) async {
    chartRepository.responder = (_, _) => const [];
    await openDetails(tester, 'BTCUSDT');

    expect(find.text(AppStrings.chartEmptyTitle), findsOneWidget);
    expect(find.byType(LineChart), findsNothing);
    expect(summaryText(r'$80,600.01'), findsOneWidget);
  });

  testWidgets('touching the chart shows the selected candle', (tester) async {
    await openDetails(tester, 'BTCUSDT');
    final chart = find.byType(LineChart);

    final gesture = await tester.startGesture(tester.getCenter(chart));
    await tester.pump(kLongPressTimeout);
    await gesture.moveBy(const Offset(10, 0));
    await tester.pump();

    expect(find.textContaining('O \$'), findsOneWidget);
    expect(find.text(AppStrings.chartRangeCaption('24H')), findsNothing);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.chartRangeCaption('24H')), findsOneWidget);
  });

  testWidgets('live ticker updates refresh the price without new history '
      'requests', (tester) async {
    await openDetails(tester, 'BTCUSDT');
    await tester.tap(find.text(AppStrings.timeframeFourHours));
    await tester.pumpAndSettle();
    final requestsBefore = chartRepository.requests.length;

    marketRepository
      ..emitStatus(LiveConnectionStatus.connected)
      ..emitUpdate(
        buildUpdate(
          symbol: 'BTCUSDT',
          lastPrice: 81234.5,
          priceChangePercent: 1.2,
        ),
      );
    await tester.pump();

    expect(summaryText(r'$81,234.50'), findsOneWidget);
    expect(summaryText('+1.20%'), findsOneWidget);
    expect(find.text(AppStrings.liveStatusLive), findsOneWidget);
    expect(chartRepository.requests, hasLength(requestsBefore));
    expect(find.text(AppStrings.chartRangeCaption('4H')), findsOneWidget);
  });

  testWidgets('keeps the last price when the live connection drops', (
    tester,
  ) async {
    await openDetails(tester, 'BTCUSDT');

    marketRepository.emitStatus(LiveConnectionStatus.disconnected);
    await tester.pump();

    expect(find.text(AppStrings.liveStatusOffline), findsOneWidget);
    expect(find.text(AppStrings.liveStatusLive), findsNothing);
    expect(summaryText(r'$80,600.01'), findsOneWidget);
  });

  testWidgets('unknown symbols show a not-found screen', (tester) async {
    await openDetails(tester, 'NOPEUSDT');

    expect(find.text(AppStrings.coinNotFoundTitle), findsOneWidget);
    expect(chartRepository.requests, isEmpty);

    await tester.tap(find.text(AppStrings.backToMarkets));
    await tester.pumpAndSettle();

    expect(find.byType(MarketScreen), findsOneWidget);
  });

  testWidgets('route symbols are case-insensitive', (tester) async {
    await openDetails(tester, 'ethusdt');

    expect(find.text('ETH / USDT'), findsOneWidget);
    expect(chartRepository.requests.single.symbol, 'ETHUSDT');
  });

  testWidgets('the star adds and removes the pair from the watchlist', (
    tester,
  ) async {
    await openDetails(tester, 'ETHUSDT');

    await tester.tap(find.byTooltip(AppStrings.addToWatchlist('ETHUSDT')));
    await tester.pumpAndSettle();

    expect(watchlistStorage.symbols, ['ETHUSDT']);
    expect(
      find.byTooltip(AppStrings.removeFromWatchlist('ETHUSDT')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip(AppStrings.removeFromWatchlist('ETHUSDT')));
    await tester.pumpAndSettle();

    expect(watchlistStorage.symbols, isEmpty);
    expect(
      find.byTooltip(AppStrings.addToWatchlist('ETHUSDT')),
      findsOneWidget,
    );
  });

  testWidgets('a failed save keeps the star unchanged and reports it', (
    tester,
  ) async {
    watchlistStorage.failWrites = true;
    await openDetails(tester, 'ETHUSDT');

    await tester.tap(find.byTooltip(AppStrings.addToWatchlist('ETHUSDT')));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.watchlistWriteError), findsOneWidget);
    expect(
      find.byTooltip(AppStrings.addToWatchlist('ETHUSDT')),
      findsOneWidget,
    );
    expect(watchlistStorage.symbols, isEmpty);
  });

  testWidgets('lays out without overflow on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    marketRepository.emitStatus(LiveConnectionStatus.reconnecting);
    await openDetails(tester, 'DOGEUSDT');

    await tester.tap(find.text(AppStrings.timeframeThirtyDays));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(CoinMarketStats), 200);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.liveStatusReconnecting), findsOneWidget);
  });
}
