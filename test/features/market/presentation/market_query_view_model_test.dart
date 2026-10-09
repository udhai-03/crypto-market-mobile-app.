import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/features/market/presentation/models/market_query.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_query_view_model.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_selectors.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_view_model.dart';
import 'package:crypto_market_mobile/features/market/providers/market_providers.dart';

import '../../../helpers/fake_market_repository.dart';

void main() {
  late FakeMarketRepository repository;
  late ProviderContainer container;

  MarketQueryViewModel queryViewModel() =>
      container.read(marketQueryProvider.notifier);

  List<String> visibleSymbols() => [
    for (final ticker in container.read(visibleMarketTickersProvider))
      ticker.symbol,
  ];

  setUp(() async {
    repository = FakeMarketRepository([
      () => sampleTickers,
      () => [sampleTickers.first],
    ]);
    container = ProviderContainer(
      overrides: [marketRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(visibleMarketTickersProvider, (_, _) {});
    await container.read(marketViewModelProvider.future);
  });

  test('shows all tickers in API order by default', () {
    expect(visibleSymbols(), [
      'BTCUSDT',
      'ETHUSDT',
      'BNBUSDT',
      'ADAUSDT',
      'TRXUSDT',
    ]);
  });

  test('search is case-insensitive and matches part of the symbol', () {
    for (final searchText in ['btc', 'BTC', 'BtC', '  btc ']) {
      queryViewModel().updateSearch(searchText);
      expect(visibleSymbols(), ['BTCUSDT'], reason: searchText);
    }
  });

  test('search with no matches returns an empty list', () {
    queryViewModel().updateSearch('DOGE');

    expect(visibleSymbols(), isEmpty);
  });

  test('gainers filter keeps only positive changes', () {
    queryViewModel().selectFilter(MarketFilter.gainers);

    expect(visibleSymbols(), ['ETHUSDT', 'ADAUSDT']);
  });

  test('losers filter keeps only negative changes', () {
    queryViewModel().selectFilter(MarketFilter.losers);

    expect(visibleSymbols(), ['BTCUSDT', 'BNBUSDT']);
  });

  test('sorts by price in both directions', () {
    queryViewModel().selectSort(MarketSort.priceHighToLow);
    expect(visibleSymbols(), [
      'BTCUSDT',
      'ETHUSDT',
      'BNBUSDT',
      'TRXUSDT',
      'ADAUSDT',
    ]);

    queryViewModel().selectSort(MarketSort.priceLowToHigh);
    expect(visibleSymbols(), [
      'ADAUSDT',
      'TRXUSDT',
      'BNBUSDT',
      'ETHUSDT',
      'BTCUSDT',
    ]);
  });

  test('sorts by 24h change in both directions', () {
    queryViewModel().selectSort(MarketSort.changeHighToLow);
    expect(visibleSymbols(), [
      'ADAUSDT',
      'ETHUSDT',
      'TRXUSDT',
      'BTCUSDT',
      'BNBUSDT',
    ]);

    queryViewModel().selectSort(MarketSort.changeLowToHigh);
    expect(visibleSymbols(), [
      'BNBUSDT',
      'BTCUSDT',
      'TRXUSDT',
      'ETHUSDT',
      'ADAUSDT',
    ]);
  });

  test('sorts by volume from high to low', () {
    queryViewModel().selectSort(MarketSort.volumeHighToLow);

    expect(visibleSymbols(), [
      'BTCUSDT',
      'ETHUSDT',
      'BNBUSDT',
      'ADAUSDT',
      'TRXUSDT',
    ]);
  });

  test('combines search, filter, and sort', () {
    queryViewModel()
      ..updateSearch('usdt')
      ..selectFilter(MarketFilter.gainers)
      ..selectSort(MarketSort.changeHighToLow);
    expect(visibleSymbols(), ['ADAUSDT', 'ETHUSDT']);

    queryViewModel().updateSearch('eth');
    expect(visibleSymbols(), ['ETHUSDT']);

    queryViewModel().updateSearch('btc');
    expect(visibleSymbols(), isEmpty);
  });

  test('clearing search and filter keeps the selected sort', () {
    queryViewModel()
      ..updateSearch('btc')
      ..selectFilter(MarketFilter.losers)
      ..selectSort(MarketSort.priceLowToHigh)
      ..clearSearchAndFilter();

    expect(
      container.read(marketQueryProvider),
      const MarketQuery(sort: MarketSort.priceLowToHigh),
    );
    expect(visibleSymbols().first, 'ADAUSDT');
  });

  test('changing the query never refetches and keeps source data intact', () {
    queryViewModel()
      ..updateSearch('eth')
      ..selectFilter(MarketFilter.losers)
      ..selectSort(MarketSort.volumeHighToLow);

    expect(repository.callCount, 1);
    expect(container.read(marketViewModelProvider).value, sampleTickers);
    expect(sampleTickers.first.symbol, 'BTCUSDT');
  });

  test('refresh reloads data and keeps the active query applied', () async {
    queryViewModel().selectFilter(MarketFilter.losers);

    await container.read(marketViewModelProvider.notifier).refresh();

    expect(repository.callCount, 2);
    expect(visibleSymbols(), ['BTCUSDT']);
    expect(container.read(marketQueryProvider).filter, MarketFilter.losers);
  });

  test('summary is derived from all loaded tickers, ignoring the query', () {
    queryViewModel().updateSearch('btc');

    final summary = container.read(marketSummaryProvider);

    expect(summary.trackedCount, 5);
    expect(summary.gainersCount, 2);
    expect(summary.losersCount, 2);
    expect(summary.averageChangePercent, closeTo(-0.56, 1e-9));
    expect(summary.topVolumeTicker?.symbol, 'BTCUSDT');
  });
}
