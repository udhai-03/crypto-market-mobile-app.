import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/app/app.dart';
import 'package:crypto_market_mobile/app/router/app_router.dart';
import 'package:crypto_market_mobile/core/constants/app_routes.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/features/market/domain/models/live_connection_status.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/market_query.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/live_status_indicator.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_controls.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_state_views.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_summary_section.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_ticker_tile.dart';
import 'package:crypto_market_mobile/features/market/providers/market_providers.dart';
import 'package:crypto_market_mobile/features/watchlist/providers/watchlist_providers.dart';

import 'helpers/fake_market_repository.dart';
import 'helpers/fake_watchlist_storage.dart';

void main() {
  const tallPhoneSize = Size(412, 1600);

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.single;
    view
      ..physicalSize = tallPhoneSize
      ..devicePixelRatio = 1;
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.single.reset();
  });

  Widget buildApp(FakeMarketRepository repository) {
    return ProviderScope(
      overrides: [
        marketRepositoryProvider.overrideWithValue(repository),
        watchlistStorageProvider.overrideWithValue(FakeWatchlistStorage()),
      ],
      child: const CryptoMarketApp(),
    );
  }

  Future<void> pumpMarket(
    WidgetTester tester, [
    List<MarketTicker>? tickers,
  ]) async {
    await tester.pumpWidget(
      buildApp(FakeMarketRepository([() => tickers ?? sampleTickers])),
    );
    await tester.pumpAndSettle();
  }

  Finder tileFor(String symbol) =>
      find.widgetWithText(MarketTickerTile, symbol);

  Finder sortOption(MarketSort sort) =>
      find.widgetWithText(CheckedPopupMenuItem<MarketSort>, sort.label);

  Finder filterSegment(MarketFilter filter) => find.descendant(
    of: find.byType(MarketFilterBar),
    matching: find.text(filter.label),
  );

  testWidgets('shows a loading skeleton, then the market dashboard', (
    tester,
  ) async {
    final response = Completer<List<MarketTicker>>();
    await tester.pumpWidget(
      buildApp(FakeMarketRepository([() => response.future])),
    );
    await tester.pump();

    expect(find.byType(MarketLoadingSliver), findsOneWidget);
    expect(find.text(AppStrings.marketsTitle), findsOneWidget);

    response.complete(sampleTickers);
    await tester.pumpAndSettle();

    expect(find.byType(MarketLoadingSliver), findsNothing);
    expect(find.text(AppStrings.summaryTitle), findsOneWidget);
    expect(find.text(AppStrings.pairCount(5)), findsOneWidget);
    expect(tileFor('BTCUSDT'), findsOneWidget);
    expect(find.text(r'$80,600.01'), findsOneWidget);
    expect(find.text('-3.30%'), findsOneWidget);
    expect(
      find.descendant(
        of: tileFor('BTCUSDT'),
        matching: find.text(AppStrings.shortVolume('1.71B')),
      ),
      findsOneWidget,
    );
  });

  testWidgets('summary statistics describe only the tracked pairs', (
    tester,
  ) async {
    await pumpMarket(tester);

    void expectStat(String label, String value) {
      expect(
        find.descendant(
          of: find.widgetWithText(MarketMetric, label),
          matching: find.text(value),
        ),
        findsOneWidget,
        reason: label,
      );
    }

    expect(find.text(AppStrings.marketsSubtitle), findsOneWidget);
    expect(find.text(AppStrings.summaryCaption), findsOneWidget);
    expectStat(AppStrings.statTrackedPairs, '5');
    expectStat(AppStrings.statGainers, '2');
    expectStat(AppStrings.statLosers, '2');
    expectStat(AppStrings.statAverageChange, '-0.56%');
    expectStat(AppStrings.statTopVolume, 'BTC');
    expectStat(AppStrings.statTopGainer, 'ADA');
    expectStat(AppStrings.statTopGainer, '+4.80%');
    expectStat(AppStrings.statTopLoser, 'BNB');
    expectStat(AppStrings.statTopLoser, '-6.40%');
    expectStat(AppStrings.statTopVolume, '1.71B USDT');
  });

  testWidgets('search filters the list case-insensitively', (tester) async {
    await pumpMarket(tester);

    await tester.enterText(find.byType(TextField), 'eth');
    await tester.pumpAndSettle();

    expect(tileFor('ETHUSDT'), findsOneWidget);
    expect(tileFor('BTCUSDT'), findsNothing);
    expect(find.text(AppStrings.pairCount(1)), findsOneWidget);
  });

  testWidgets('empty search result offers to clear search and filter', (
    tester,
  ) async {
    await pumpMarket(tester);

    await tester.enterText(find.byType(TextField), 'nothing');
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.noResultsTitle), findsOneWidget);
    expect(find.text(AppStrings.errorTitle), findsNothing);

    await tester.tap(find.text(AppStrings.clearSearchAndFilter));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.pairCount(5)), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      isEmpty,
    );
  });

  testWidgets('filter and sort update the visible list', (tester) async {
    await pumpMarket(tester);

    await tester.ensureVisible(filterSegment(MarketFilter.losers));
    await tester.pumpAndSettle();
    await tester.tap(filterSegment(MarketFilter.losers));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.pairCount(2)), findsOneWidget);
    expect(tileFor('ETHUSDT'), findsNothing);

    await tester.ensureVisible(find.byType(MarketSortMenu));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MarketSortMenu));
    await tester.pumpAndSettle();
    await tester.tap(sortOption(MarketSort.changeLowToHigh));
    await tester.pumpAndSettle();

    final bnbTop = tester.getTopLeft(tileFor('BNBUSDT')).dy;
    final btcTop = tester.getTopLeft(tileFor('BTCUSDT')).dy;
    expect(bnbTop, lessThan(btcTop));
  });

  testWidgets('shows an error with retry that reloads data', (tester) async {
    final repository = FakeMarketRepository([
      () => throw const NoConnectionException(),
      () => sampleTickers,
    ]);
    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.errorTitle), findsOneWidget);
    expect(find.text(AppStrings.noConnectionError), findsOneWidget);

    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();

    expect(tileFor('BTCUSDT'), findsOneWidget);
    expect(repository.callCount, 2);
  });

  testWidgets('pull-to-refresh reloads through the view model', (tester) async {
    final repository = FakeMarketRepository([
      () => sampleTickers,
      () => [sampleTickers.first],
    ]);
    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    await tester.fling(
      find.text(AppStrings.marketsTitle),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(repository.callCount, 2);
    expect(find.text(AppStrings.pairCount(1)), findsOneWidget);
  });

  testWidgets('shows an empty state when the API returns no tickers', (
    tester,
  ) async {
    await pumpMarket(tester, const []);

    expect(find.text(AppStrings.marketEmptyTitle), findsOneWidget);
  });

  testWidgets('lays out without overflow on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);

    await pumpMarket(tester);
    await tester.scrollUntilVisible(
      find.byType(MarketSortMenu),
      100,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MarketSortMenu));
    await tester.pumpAndSettle();
    await tester.tap(sortOption(MarketSort.changeHighToLow));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(MarketSort.changeHighToLow.label), findsOneWidget);
  });

  testWidgets('shows the live status and applies live price updates', (
    tester,
  ) async {
    final repository = FakeMarketRepository([() => sampleTickers]);
    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.liveStatusConnecting), findsOneWidget);

    repository
      ..emitStatus(LiveConnectionStatus.connected)
      ..emitUpdate(
        buildUpdate(
          symbol: 'BTCUSDT',
          lastPrice: 81234.5,
          priceChangePercent: 1.2,
        ),
      );
    await tester.pump();

    expect(find.text(AppStrings.liveStatusLive), findsOneWidget);
    expect(find.text(r'$81,234.50'), findsOneWidget);
    expect(find.text('+1.20%'), findsOneWidget);
    expect(find.text(r'$80,600.01'), findsNothing);
  });

  testWidgets('keeps last prices visible when the live connection drops', (
    tester,
  ) async {
    final repository = FakeMarketRepository([() => sampleTickers]);
    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    repository.emitStatus(LiveConnectionStatus.reconnecting);
    await tester.pump();
    expect(find.text(AppStrings.liveStatusReconnecting), findsOneWidget);

    repository.emitStatus(LiveConnectionStatus.disconnected);
    await tester.pump();
    expect(find.text(AppStrings.liveStatusOffline), findsOneWidget);
    expect(find.text(AppStrings.liveStatusLive), findsNothing);
    expect(tileFor('BTCUSDT'), findsOneWidget);
    expect(find.text(r'$80,600.01'), findsOneWidget);
  });

  testWidgets('hides the live status until market data has loaded', (
    tester,
  ) async {
    final response = Completer<List<MarketTicker>>();
    await tester.pumpWidget(
      buildApp(FakeMarketRepository([() => response.future])),
    );
    await tester.pump();

    expect(find.byType(LiveStatusIndicator), findsOneWidget);
    expect(find.text(AppStrings.liveStatusConnecting), findsNothing);

    response.complete(sampleTickers);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.liveStatusConnecting), findsOneWidget);
  });

  testWidgets('header with live status fits on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    final repository = FakeMarketRepository([() => sampleTickers]);
    await tester.pumpWidget(buildApp(repository));
    await tester.pumpAndSettle();

    repository.emitStatus(LiveConnectionStatus.reconnecting);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.liveStatusReconnecting), findsOneWidget);
  });

  testWidgets('switches to the watchlist tab', (tester) async {
    await pumpMarket(tester);

    await tester.tap(find.text(AppStrings.watchlist));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.watchlistSubtitle), findsOneWidget);
    expect(find.text(AppStrings.watchlistEmptyTitle), findsOneWidget);
  });

  testWidgets('opens coin details from its route', (tester) async {
    final container = ProviderContainer(
      overrides: [
        marketRepositoryProvider.overrideWithValue(
          FakeMarketRepository([() => sampleTickers]),
        ),
        watchlistStorageProvider.overrideWithValue(FakeWatchlistStorage()),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const CryptoMarketApp(),
      ),
    );
    await tester.pumpAndSettle();

    container
        .read(appRouterProvider)
        .go(AppRoutes.coinDetailsLocation('route-check'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.coinDetails), findsOneWidget);
    expect(find.text(AppStrings.coinNotFoundTitle), findsOneWidget);
  });
}
