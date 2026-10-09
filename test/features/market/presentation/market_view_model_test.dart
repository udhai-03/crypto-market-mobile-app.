import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_view_model.dart';
import 'package:crypto_market_mobile/features/market/providers/market_providers.dart';

import '../../../helpers/fake_market_repository.dart';

void main() {
  ProviderContainer createContainer(FakeMarketRepository repository) {
    final container = ProviderContainer(
      overrides: [marketRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('loads market data from the repository', () async {
    final tickers = [buildTicker()];
    final container = createContainer(FakeMarketRepository([() => tickers]));

    expect(container.read(marketViewModelProvider).isLoading, isTrue);

    final result = await container.read(marketViewModelProvider.future);

    expect(result, tickers);
  });

  test('exposes repository failures as an error state', () async {
    final container = createContainer(
      FakeMarketRepository([() => throw const NoConnectionException()]),
    );

    await expectLater(
      container.read(marketViewModelProvider.future),
      throwsA(isA<NoConnectionException>()),
    );

    final state = container.read(marketViewModelProvider);
    expect(state.error, isA<NoConnectionException>());
    expect(state.isLoading, isFalse);
  });

  test('refresh recovers from an error', () async {
    final tickers = [buildTicker(symbol: 'ETHUSDT')];
    final repository = FakeMarketRepository([
      () => throw const RequestTimeoutException(),
      () => tickers,
    ]);
    final container = createContainer(repository);
    final subscription = container.listen(marketViewModelProvider, (_, _) {});
    addTearDown(subscription.close);

    await expectLater(
      container.read(marketViewModelProvider.future),
      throwsA(isA<RequestTimeoutException>()),
    );

    await container.read(marketViewModelProvider.notifier).refresh();

    expect(container.read(marketViewModelProvider).value, tickers);
    expect(repository.callCount, 2);
  });

  test('failed refresh keeps the previously loaded data', () async {
    final tickers = [buildTicker()];
    final container = createContainer(
      FakeMarketRepository([
        () => tickers,
        () => throw const ServerException(500),
      ]),
    );
    final subscription = container.listen(marketViewModelProvider, (_, _) {});
    addTearDown(subscription.close);

    await container.read(marketViewModelProvider.future);
    await container.read(marketViewModelProvider.notifier).refresh();

    final AsyncValue<List<MarketTicker>> state = container.read(
      marketViewModelProvider,
    );
    expect(state.error, isA<ServerException>());
    expect(state.value, tickers);
  });
}
