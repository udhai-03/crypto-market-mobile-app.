import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/features/watchlist/data/watchlist_storage.dart';

class _FailingPreferences implements SharedPreferencesAsync {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      Future<Never>.error(StateError('storage unavailable'));
}

Matcher _storageError(String message) => throwsA(
  isA<StorageException>().having((error) => error.message, 'message', message),
);

void main() {
  const key = SharedPreferencesWatchlistStorage.storageKey;

  late SharedPreferencesAsync preferences;
  late SharedPreferencesWatchlistStorage storage;

  void useStore(InMemorySharedPreferencesAsync store) {
    SharedPreferencesAsyncPlatform.instance = store;
    preferences = SharedPreferencesAsync();
    storage = SharedPreferencesWatchlistStorage(preferences);
  }

  setUp(() => useStore(InMemorySharedPreferencesAsync.empty()));

  test('reads an empty watchlist when nothing was saved', () async {
    expect(await storage.readSymbols(), isEmpty);
  });

  test('restores saved symbols with a new storage instance', () async {
    await storage.writeSymbols(['SOLUSDT', 'BTCUSDT']);

    final restored = SharedPreferencesWatchlistStorage(
      SharedPreferencesAsync(),
    );

    expect(await restored.readSymbols(), ['SOLUSDT', 'BTCUSDT']);
  });

  test('stores the versioned JSON format', () async {
    await storage.writeSymbols(['BTCUSDT']);

    expect(
      await preferences.getString(key),
      '{"version":1,"symbols":["BTCUSDT"]}',
    );
  });

  test('corrupt data fails the read and is left untouched', () async {
    const corrupt = '{"version":1,"symbols":[7]}';
    useStore(InMemorySharedPreferencesAsync.withData({key: corrupt}));

    await expectLater(
      storage.readSymbols(),
      _storageError(AppStrings.watchlistReadError),
    );
    expect(await preferences.getString(key), corrupt);
  });

  test('platform read failures become storage errors', () async {
    final failing = SharedPreferencesWatchlistStorage(_FailingPreferences());

    await expectLater(
      failing.readSymbols(),
      _storageError(AppStrings.watchlistReadError),
    );
  });

  test('platform write failures become storage errors', () async {
    final failing = SharedPreferencesWatchlistStorage(_FailingPreferences());

    await expectLater(
      failing.writeSymbols(['BTCUSDT']),
      _storageError(AppStrings.watchlistWriteError),
    );
  });
}
