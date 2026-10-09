import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/features/watchlist/presentation/viewmodels/watchlist_view_model.dart';
import 'package:crypto_market_mobile/features/watchlist/providers/watchlist_providers.dart';

import '../../../helpers/fake_watchlist_storage.dart';

void main() {
  late FakeWatchlistStorage storage;

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [watchlistStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<(ProviderContainer, WatchlistViewModel)> loaded() async {
    final container = createContainer();
    await container.read(watchlistViewModelProvider.future);
    return (container, container.read(watchlistViewModelProvider.notifier));
  }

  setUp(() => storage = FakeWatchlistStorage());

  test('restores the saved watchlist on start', () async {
    storage.symbols = ['ETHUSDT', 'BTCUSDT'];
    final (container, _) = await loaded();

    expect(container.read(watchlistViewModelProvider).value, [
      'ETHUSDT',
      'BTCUSDT',
    ]);
  });

  test('is loading until storage responds', () async {
    storage.readGate = Completer<void>();
    final container = createContainer();
    final subscription = container.listen(
      watchlistViewModelProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    expect(container.read(watchlistViewModelProvider).isLoading, isTrue);
    expect(container.read(watchlistMembershipProvider('BTCUSDT')), isNull);

    storage.readGate!.complete();
    await container.read(watchlistViewModelProvider.future);

    expect(container.read(watchlistMembershipProvider('BTCUSDT')), isFalse);
  });

  test('add saves the symbol and persists it', () async {
    final (container, viewModel) = await loaded();

    expect(await viewModel.add('solusdt'), isTrue);

    expect(container.read(watchlistViewModelProvider).value, ['SOLUSDT']);
    expect(storage.symbols, ['SOLUSDT']);
    expect(container.read(watchlistMembershipProvider('SOLUSDT')), isTrue);
  });

  test('adding a saved symbol is an idempotent no-op', () async {
    storage.symbols = ['BTCUSDT'];
    final (container, viewModel) = await loaded();

    expect(await viewModel.add('BTCUSDT'), isTrue);

    expect(container.read(watchlistViewModelProvider).value, ['BTCUSDT']);
    expect(storage.writeCount, 0);
  });

  test('remove deletes the symbol and persists it', () async {
    storage.symbols = ['BTCUSDT', 'ETHUSDT'];
    final (container, viewModel) = await loaded();

    expect(await viewModel.remove('BTCUSDT'), isTrue);

    expect(container.read(watchlistViewModelProvider).value, ['ETHUSDT']);
    expect(storage.symbols, ['ETHUSDT']);
  });

  test('removing an absent symbol is safe', () async {
    storage.symbols = ['BTCUSDT'];
    final (container, viewModel) = await loaded();

    expect(await viewModel.remove('ETHUSDT'), isTrue);

    expect(container.read(watchlistViewModelProvider).value, ['BTCUSDT']);
    expect(storage.writeCount, 0);
  });

  test('a failed save keeps the previous state and reports failure', () async {
    storage.symbols = ['BTCUSDT'];
    final (container, viewModel) = await loaded();
    storage.failWrites = true;

    expect(await viewModel.add('ETHUSDT'), isFalse);
    expect(await viewModel.remove('BTCUSDT'), isFalse);

    final state = container.read(watchlistViewModelProvider);
    expect(state.hasError, isFalse);
    expect(state.value, ['BTCUSDT']);
    expect(storage.symbols, ['BTCUSDT']);
  });

  test('invalid symbols are rejected without saving', () async {
    final (_, viewModel) = await loaded();

    expect(await viewModel.add('not a symbol'), isFalse);
    expect(storage.writeCount, 0);
  });

  test('rapid toggles apply in order', () async {
    final (container, viewModel) = await loaded();

    final results = await Future.wait([
      viewModel.toggle('BTCUSDT'),
      viewModel.toggle('BTCUSDT'),
      viewModel.toggle('BTCUSDT'),
    ]);

    expect(results, [true, true, true]);
    expect(container.read(watchlistViewModelProvider).value, ['BTCUSDT']);
    expect(storage.writeCount, 3);
  });

  test('read failures surface an error and changes are refused', () async {
    storage.failReads = true;
    final container = createContainer();

    await expectLater(
      container.read(watchlistViewModelProvider.future),
      throwsA(isA<StorageException>()),
    );
    final viewModel = container.read(watchlistViewModelProvider.notifier);
    final state = container.read(watchlistViewModelProvider);

    expect(state.error, isA<StorageException>());
    expect(
      (state.error! as StorageException).message,
      AppStrings.watchlistReadError,
    );
    expect(await viewModel.add('BTCUSDT'), isFalse);
    expect(storage.writeCount, 0);
  });

  test('reload recovers after a read failure', () async {
    storage
      ..symbols = ['BTCUSDT']
      ..failReads = true;
    final container = createContainer();
    await expectLater(
      container.read(watchlistViewModelProvider.future),
      throwsA(isA<StorageException>()),
    );

    storage.failReads = false;
    await container.read(watchlistViewModelProvider.notifier).reload();

    expect(container.read(watchlistViewModelProvider).value, ['BTCUSDT']);
  });
}
