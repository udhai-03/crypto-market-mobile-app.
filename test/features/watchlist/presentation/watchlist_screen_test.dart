import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/app/app.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/core/widgets/skeleton_box.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/views/coin_details_screen.dart';
import 'package:crypto_market_mobile/features/coin_details/providers/coin_details_providers.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/presentation/views/market_screen.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_ticker_tile.dart';
import 'package:crypto_market_mobile/features/market/providers/market_providers.dart';
import 'package:crypto_market_mobile/features/watchlist/presentation/views/watchlist_screen.dart';
import 'package:crypto_market_mobile/features/watchlist/presentation/widgets/watchlist_tile.dart';
import 'package:crypto_market_mobile/features/watchlist/providers/watchlist_providers.dart';

import '../../../helpers/fake_chart_repository.dart';
import '../../../helpers/fake_market_repository.dart';
import '../../../helpers/fake_watchlist_storage.dart';

void main() {
  const tallPhoneSize = Size(412, 1600);

  late FakeMarketRepository marketRepository;
  late FakeChartRepository chartRepository;
  late FakeWatchlistStorage storage;

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.single;
    view
      ..physicalSize = tallPhoneSize
      ..devicePixelRatio = 1;
    marketRepository = FakeMarketRepository([() => sampleTickers]);
    chartRepository = FakeChartRepository();
    storage = FakeWatchlistStorage();
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.single.reset();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketRepositoryProvider.overrideWithValue(marketRepository),
          chartRepositoryProvider.overrideWithValue(chartRepository),
          watchlistStorageProvider.overrideWithValue(storage),
        ],
        child: const CryptoMarketApp(),
      ),
    );
    await tester.pump();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openWatchlist(WidgetTester tester) =>
      openTab(tester, AppStrings.watchlist);

  Finder watchlistTile(String symbol) =>
      find.widgetWithText(WatchlistTile, symbol);

  Finder addStar(String symbol) =>
      find.byTooltip(AppStrings.addToWatchlist(symbol));

  Finder removeStar(String symbol) =>
      find.byTooltip(AppStrings.removeFromWatchlist(symbol));

  testWidgets('shows an empty state that leads back to the market', (
    tester,
  ) async {
    await pumpApp(tester);
    await openWatchlist(tester);

    expect(find.text(AppStrings.watchlistEmptyTitle), findsOneWidget);
    expect(find.text(AppStrings.watchlistEmptyMessage), findsOneWidget);

    await tester.tap(find.text(AppStrings.browseMarkets));
    await tester.pumpAndSettle();

    expect(find.byType(MarketScreen), findsOneWidget);
  });

  testWidgets('restores saved pairs with their latest prices', (tester) async {
    storage.symbols = ['ETHUSDT', 'BTCUSDT'];
    await pumpApp(tester);
    await openWatchlist(tester);

    final tiles = find.byType(WatchlistTile);
    expect(tiles, findsNWidgets(2));
    expect(tester.widgetList<WatchlistTile>(tiles).map((tile) => tile.symbol), [
      'ETHUSDT',
      'BTCUSDT',
    ]);
    expect(
      find.descendant(
        of: watchlistTile('ETHUSDT'),
        matching: find.text(r'$2,414.46'),
      ),
      findsOneWidget,
    );
    expect(removeStar('ETHUSDT'), findsOneWidget);
  });

  testWidgets('rows react to live ticker updates', (tester) async {
    storage.symbols = ['ETHUSDT'];
    await pumpApp(tester);
    await openWatchlist(tester);

    marketRepository.emitUpdate(
      buildUpdate(symbol: 'ETHUSDT', lastPrice: 2500, priceChangePercent: 3),
    );
    await tester.pump();

    expect(
      find.descendant(
        of: watchlistTile('ETHUSDT'),
        matching: find.text(r'$2,500.00'),
      ),
      findsOneWidget,
    );
    expect(marketRepository.callCount, 1);
  });

  testWidgets('saved pairs stay visible while prices load or fail', (
    tester,
  ) async {
    final pending = Completer<List<MarketTicker>>();
    marketRepository = FakeMarketRepository([() => pending.future]);
    storage.symbols = ['BTCUSDT'];
    await pumpApp(tester);
    await openWatchlist(tester);

    expect(watchlistTile('BTCUSDT'), findsOneWidget);
    expect(
      find.descendant(
        of: watchlistTile('BTCUSDT'),
        matching: find.byType(SkeletonBox),
      ),
      findsOneWidget,
    );
    expect(removeStar('BTCUSDT'), findsOneWidget);

    pending.completeError(const NoConnectionException());
    await tester.pumpAndSettle();

    expect(watchlistTile('BTCUSDT'), findsOneWidget);
    expect(find.text(AppStrings.watchlistPriceUnavailable), findsOneWidget);
    expect(storage.symbols, ['BTCUSDT']);
  });

  testWidgets('saved pairs missing from the market are kept as unavailable', (
    tester,
  ) async {
    storage.symbols = ['SOLUSDT'];
    await pumpApp(tester);
    await openWatchlist(tester);

    expect(watchlistTile('SOLUSDT'), findsOneWidget);
    expect(find.text(AppStrings.watchlistPriceUnavailable), findsOneWidget);
  });

  testWidgets('untracked symbols are shown, not erased, and can be removed', (
    tester,
  ) async {
    storage.symbols = ['LUNAUSDT', 'BTCUSDT'];
    await pumpApp(tester);
    await openWatchlist(tester);

    expect(tester.takeException(), isNull);
    expect(watchlistTile('LUNAUSDT'), findsOneWidget);
    expect(find.text(AppStrings.watchlistUnsupported), findsOneWidget);

    await tester.tap(watchlistTile('LUNAUSDT'));
    await tester.pumpAndSettle();
    expect(find.byType(CoinDetailsScreen), findsNothing);
    expect(storage.symbols, ['LUNAUSDT', 'BTCUSDT']);

    await tester.tap(removeStar('LUNAUSDT'));
    await tester.pumpAndSettle();

    expect(watchlistTile('LUNAUSDT'), findsNothing);
    expect(storage.symbols, ['BTCUSDT']);
  });

  testWidgets('tapping a row opens details for that pair', (tester) async {
    storage.symbols = ['BTCUSDT', 'ETHUSDT'];
    await pumpApp(tester);
    await openWatchlist(tester);

    await tester.tap(find.widgetWithText(MarketTickerTile, 'ETHUSDT'));
    await tester.pumpAndSettle();

    expect(find.byType(CoinDetailsScreen), findsOneWidget);
    expect(find.text('ETH / USDT'), findsOneWidget);
    expect(chartRepository.requests.single.symbol, 'ETHUSDT');

    await tester.tap(find.byTooltip(AppStrings.backTooltip));
    await tester.pumpAndSettle();

    expect(find.byType(WatchlistScreen), findsOneWidget);
  });

  testWidgets('removing from the watchlist screen drops the row', (
    tester,
  ) async {
    storage.symbols = ['BTCUSDT', 'ETHUSDT'];
    await pumpApp(tester);
    await openWatchlist(tester);

    await tester.tap(removeStar('BTCUSDT'));
    await tester.pumpAndSettle();

    expect(watchlistTile('BTCUSDT'), findsNothing);
    expect(watchlistTile('ETHUSDT'), findsOneWidget);
    expect(storage.symbols, ['ETHUSDT']);
  });

  testWidgets('market row stars add and remove pairs', (tester) async {
    await pumpApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(addStar('ADAUSDT'));
    await tester.pumpAndSettle();

    expect(storage.symbols, ['ADAUSDT']);
    expect(removeStar('ADAUSDT'), findsOneWidget);
    expect(find.byType(CoinDetailsScreen), findsNothing);

    await openWatchlist(tester);
    expect(watchlistTile('ADAUSDT'), findsOneWidget);

    await openTab(tester, AppStrings.market);
    await tester.tap(removeStar('ADAUSDT'));
    await tester.pumpAndSettle();

    expect(storage.symbols, isEmpty);
    expect(addStar('ADAUSDT'), findsOneWidget);
  });

  testWidgets('a failed save leaves the star unchanged and shows an error', (
    tester,
  ) async {
    storage.failWrites = true;
    await pumpApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(addStar('BTCUSDT'));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.watchlistWriteError), findsOneWidget);
    expect(addStar('BTCUSDT'), findsOneWidget);
  });

  testWidgets('stars are disabled while the watchlist is loading', (
    tester,
  ) async {
    storage.readGate = Completer<void>();
    await pumpApp(tester);
    await tester.pumpAndSettle();

    final stars = find.byTooltip(AppStrings.watchlistControlUnavailable);
    expect(stars, findsWidgets);
    final firstStar = find.ancestor(
      of: stars.first,
      matching: find.byType(IconButton),
    );
    expect(tester.widget<IconButton>(firstStar).onPressed, isNull);

    await openWatchlist(tester);
    expect(find.bySemanticsLabel(AppStrings.watchlistLoading), findsOneWidget);

    storage.readGate!.complete();
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.watchlistEmptyTitle), findsOneWidget);
  });

  testWidgets('a read failure shows an error that can be retried', (
    tester,
  ) async {
    storage
      ..symbols = ['BTCUSDT']
      ..failReads = true;
    await pumpApp(tester);
    await openWatchlist(tester);

    expect(find.text(AppStrings.watchlistLoadErrorTitle), findsOneWidget);
    expect(find.text(AppStrings.watchlistReadError), findsOneWidget);

    storage.failReads = false;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();

    expect(watchlistTile('BTCUSDT'), findsOneWidget);
    expect(storage.symbols, ['BTCUSDT']);
  });

  testWidgets('lays out without overflow on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    storage.symbols = ['BTCUSDT', 'LUNAUSDT', 'SOLUSDT', 'DOGEUSDT'];
    await pumpApp(tester);
    await openWatchlist(tester);

    expect(tester.takeException(), isNull);
    expect(watchlistTile('BTCUSDT'), findsOneWidget);
  });
}
