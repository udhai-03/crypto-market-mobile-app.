import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/features/market/domain/models/live_connection_status.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/market_query.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_query_view_model.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_selectors.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_view_model.dart';
import 'package:crypto_market_mobile/features/market/providers/market_providers.dart';

import '../../../helpers/fake_market_repository.dart';

void main() {
  late FakeMarketRepository repository;
  late ProviderContainer container;

  Future<void> loadSnapshot([
    List<FutureOr<List<MarketTicker>> Function()>? responses,
  ]) async {
    repository = FakeMarketRepository(responses ?? [() => sampleTickers]);
    container = ProviderContainer(
      overrides: [marketRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(marketViewModelProvider, (_, _) {});
    addTearDown(subscription.close);
    await container.read(marketViewModelProvider.future);
  }

  List<MarketTicker> tickers() =>
      container.read(marketViewModelProvider).value!;

  MarketTicker tickerFor(String symbol) =>
      tickers().singleWhere((ticker) => ticker.symbol == symbol);

  test('loads the REST snapshot and subscribes to live updates', () async {
    await loadSnapshot();

    expect(tickers(), sampleTickers);
    expect(repository.hasLiveListener, isTrue);
  });

  test('updates every live field of the matching symbol only', () async {
    await loadSnapshot();
    final before = tickers();

    repository.emitUpdate(
      buildUpdate(
        symbol: 'ETHUSDT',
        lastPrice: 2600,
        priceChange: 40,
        priceChangePercent: 7.5,
        highPrice: 2650,
        lowPrice: 2400,
        volume: 123,
        quoteVolume: 5e8,
      ),
    );

    final eth = tickerFor('ETHUSDT');
    expect(eth.symbol, 'ETHUSDT');
    expect(eth.lastPrice, 2600);
    expect(eth.priceChange, 40);
    expect(eth.priceChangePercent, 7.5);
    expect(eth.highPrice, 2650);
    expect(eth.lowPrice, 2400);
    expect(eth.volume, 123);
    expect(eth.quoteVolume, 5e8);

    final after = tickers();
    expect(after.map((ticker) => ticker.symbol), [
      for (final ticker in before) ticker.symbol,
    ]);
    for (var i = 0; i < before.length; i++) {
      if (before[i].symbol == 'ETHUSDT') continue;
      expect(identical(after[i], before[i]), isTrue);
    }
  });

  test('replaces the list immutably', () async {
    await loadSnapshot();
    final before = tickers();

    repository.emitUpdate(buildUpdate(symbol: 'BTCUSDT', lastPrice: 1));

    expect(identical(tickers(), before), isFalse);
    expect(before.first.lastPrice, sampleTickers.first.lastPrice);
    expect(() => tickers().add(buildTicker()), throwsUnsupportedError);
  });

  test('applies repeated updates in order', () async {
    await loadSnapshot();

    for (final price in [1.0, 2.0, 3.0]) {
      repository.emitUpdate(buildUpdate(symbol: 'BTCUSDT', lastPrice: price));
    }

    expect(tickerFor('BTCUSDT').lastPrice, 3);
  });

  test('ignores updates for untracked symbols', () async {
    await loadSnapshot();
    final before = tickers();

    repository.emitUpdate(buildUpdate(symbol: 'PEPEUSDT'));

    expect(identical(tickers(), before), isTrue);
  });

  group('snapshot and live update ordering', () {
    late Completer<List<MarketTicker>> pendingSnapshot;

    Future<List<MarketTicker>> startInitialLoad() {
      pendingSnapshot = Completer<List<MarketTicker>>();
      repository = FakeMarketRepository([() => pendingSnapshot.future]);
      container = ProviderContainer(
        overrides: [marketRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(marketViewModelProvider, (_, _) {});
      addTearDown(subscription.close);
      return container.read(marketViewModelProvider.future);
    }

    test('updates received during the initial load are kept when newer '
        'than the snapshot', () async {
      final loaded = startInitialLoad();

      repository.emitUpdate(buildUpdate(symbol: 'BTCUSDT', lastPrice: 1));
      pendingSnapshot.complete(sampleTickers);
      await loaded;

      expect(tickerFor('BTCUSDT').lastPrice, 1);
      expect(tickerFor('BTCUSDT').updatedAt, liveUpdateTime);
      expect(tickerFor('ETHUSDT'), sampleTickers[1]);
    });

    test('updates older than the snapshot are discarded', () async {
      final loaded = startInitialLoad();

      repository.emitUpdate(
        buildUpdate(
          symbol: 'BTCUSDT',
          lastPrice: 1,
          updatedAt: snapshotTime.subtract(const Duration(seconds: 5)),
        ),
      );
      pendingSnapshot.complete(sampleTickers);
      await loaded;

      expect(tickers(), sampleTickers);
    });

    test('updates during a refresh are applied after it completes and the '
        'refresh stays loading until then', () async {
      final refreshed = Completer<List<MarketTicker>>();
      await loadSnapshot([() => sampleTickers, () => refreshed.future]);
      final viewModel = container.read(marketViewModelProvider.notifier);

      final refresh = viewModel.refresh();
      repository.emitUpdate(buildUpdate(symbol: 'ETHUSDT', lastPrice: 2500));

      final during = container.read(marketViewModelProvider);
      expect(during.isLoading, isTrue);
      expect(tickerFor('ETHUSDT').lastPrice, sampleTickers[1].lastPrice);

      refreshed.complete([
        buildTicker(symbol: 'BTCUSDT', lastPrice: 81000),
        buildTicker(symbol: 'ETHUSDT', lastPrice: 2400),
      ]);
      await refresh;

      expect(container.read(marketViewModelProvider).isLoading, isFalse);
      expect(tickerFor('ETHUSDT').lastPrice, 2500);
      expect(tickerFor('BTCUSDT').lastPrice, 81000);
    });

    test('an older refresh snapshot does not overwrite a newer live '
        'price', () async {
      await loadSnapshot([
        () => sampleTickers,
        () => [
          buildTicker(symbol: 'BTCUSDT', lastPrice: 79000),
          buildTicker(symbol: 'ETHUSDT', lastPrice: 2450),
        ],
      ]);
      repository.emitUpdate(buildUpdate(symbol: 'BTCUSDT', lastPrice: 82000));

      await container.read(marketViewModelProvider.notifier).refresh();

      expect(tickerFor('BTCUSDT').lastPrice, 82000);
      expect(tickerFor('ETHUSDT').lastPrice, 2450);
    });

    test('a newer refresh snapshot replaces older live values', () async {
      final later = liveUpdateTime.add(const Duration(minutes: 1));
      await loadSnapshot([
        () => sampleTickers,
        () => [buildTicker(lastPrice: 83000, updatedAt: later)],
      ]);
      repository.emitUpdate(buildUpdate(lastPrice: 82000));

      await container.read(marketViewModelProvider.notifier).refresh();

      expect(tickerFor('BTCUSDT').lastPrice, 83000);
    });

    test('out-of-order live updates are ignored', () async {
      await loadSnapshot();

      repository
        ..emitUpdate(buildUpdate(lastPrice: 2))
        ..emitUpdate(
          buildUpdate(
            lastPrice: 1,
            updatedAt: liveUpdateTime.subtract(const Duration(milliseconds: 1)),
          ),
        );

      expect(tickerFor('BTCUSDT').lastPrice, 2);
    });

    test('a slower earlier refresh cannot replace a later one', () async {
      final slow = Completer<List<MarketTicker>>();
      final fast = Completer<List<MarketTicker>>();
      await loadSnapshot([
        () => sampleTickers,
        () => slow.future,
        () => fast.future,
      ]);
      final viewModel = container.read(marketViewModelProvider.notifier);

      final first = viewModel.refresh();
      final second = viewModel.refresh();
      fast.complete([buildTicker(lastPrice: 2)]);
      await second;
      slow.completeError(const NoConnectionException());
      await first;

      final state = container.read(marketViewModelProvider);
      expect(state.hasError, isFalse);
      expect(tickers().single.lastPrice, 2);
    });
  });

  test('search, filter, and sort react to live updates', () async {
    await loadSnapshot();
    container.read(marketQueryProvider.notifier)
      ..selectFilter(MarketFilter.gainers)
      ..selectSort(MarketSort.changeHighToLow);

    List<String> visible() => [
      for (final ticker in container.read(visibleMarketTickersProvider))
        ticker.symbol,
    ];
    expect(visible(), ['ADAUSDT', 'ETHUSDT']);

    repository.emitUpdate(
      buildUpdate(symbol: 'BTCUSDT', priceChangePercent: 9),
    );
    expect(visible(), ['BTCUSDT', 'ADAUSDT', 'ETHUSDT']);

    repository.emitUpdate(
      buildUpdate(symbol: 'ADAUSDT', priceChangePercent: -1),
    );
    expect(visible(), ['BTCUSDT', 'ETHUSDT']);

    container.read(marketQueryProvider.notifier).updateSearch('eth');
    expect(visible(), ['ETHUSDT']);
  });

  test('summary statistics recalculate after an update', () async {
    await loadSnapshot();
    final before = container.read(marketSummaryProvider);
    expect(before.gainersCount, 2);
    expect(before.topVolumeTicker?.symbol, 'BTCUSDT');

    repository.emitUpdate(
      buildUpdate(symbol: 'TRXUSDT', priceChangePercent: 3, quoteVolume: 9e9),
    );

    final after = container.read(marketSummaryProvider);
    expect(after.gainersCount, 3);
    expect(after.topVolumeTicker?.symbol, 'TRXUSDT');
  });

  test(
    'connection failures keep the REST data and expose the status',
    () async {
      await loadSnapshot();
      final statusSubscription = container.listen(
        marketConnectionStatusProvider,
        (_, _) {},
      );
      addTearDown(statusSubscription.close);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(marketConnectionStatusProvider),
        LiveConnectionStatus.connecting,
      );

      repository.emitStatus(LiveConnectionStatus.reconnecting);
      expect(
        container.read(marketConnectionStatusProvider),
        LiveConnectionStatus.reconnecting,
      );

      repository.emitStatus(LiveConnectionStatus.disconnected);
      expect(
        container.read(marketConnectionStatusProvider),
        LiveConnectionStatus.disconnected,
      );
      expect(tickers(), sampleTickers);
      expect(container.read(marketViewModelProvider).hasError, isFalse);
    },
  );

  test('manual refresh reloads from REST and keeps one live '
      'subscription', () async {
    final refreshed = [buildTicker(symbol: 'BTCUSDT', lastPrice: 5)];
    await loadSnapshot([() => sampleTickers, () => refreshed]);

    await container.read(marketViewModelProvider.notifier).refresh();
    repository.emitUpdate(buildUpdate(symbol: 'BTCUSDT', lastPrice: 6));

    expect(repository.callCount, 2);
    expect(tickers().single.lastPrice, 6);
  });

  test('a live update recovers from a failed refresh', () async {
    await loadSnapshot([
      () => sampleTickers,
      () => throw const NoConnectionException(),
    ]);

    await container.read(marketViewModelProvider.notifier).refresh();
    expect(container.read(marketViewModelProvider).hasError, isTrue);

    repository.emitUpdate(buildUpdate(symbol: 'BTCUSDT', lastPrice: 7));

    final state = container.read(marketViewModelProvider);
    expect(state.hasError, isFalse);
    expect(tickerFor('BTCUSDT').lastPrice, 7);
  });

  test('pause and resume stop and restart live updates', () async {
    await loadSnapshot();
    final viewModel = container.read(marketViewModelProvider.notifier);

    viewModel.pauseLiveUpdates();
    expect(repository.hasLiveListener, isFalse);
    repository.emitUpdate(buildUpdate(symbol: 'BTCUSDT', lastPrice: 1));
    expect(tickerFor('BTCUSDT').lastPrice, sampleTickers.first.lastPrice);

    viewModel
      ..resumeLiveUpdates()
      ..resumeLiveUpdates();
    repository.emitUpdate(buildUpdate(symbol: 'BTCUSDT', lastPrice: 2));
    expect(tickerFor('BTCUSDT').lastPrice, 2);
  });

  test('disposing the view model cancels the live subscription', () async {
    await loadSnapshot();

    container.dispose();

    expect(repository.hasLiveListener, isFalse);
  });
}
