import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/features/watchlist/data/watchlist_repository.dart';

import '../../../helpers/fake_watchlist_storage.dart';

void main() {
  group('normalize', () {
    test('trims and upper-cases symbols', () {
      expect(WatchlistRepository.normalize('  btcusdt '), 'BTCUSDT');
    });

    for (final invalid in ['', ' ', 'B', 'BTC/USDT', 'btc usdt', 'X' * 31]) {
      test('rejects "$invalid"', () {
        expect(WatchlistRepository.normalize(invalid), isNull);
      });
    }
  });

  test('normalizeAll drops invalid entries and duplicates in order', () {
    expect(
      WatchlistRepository.normalizeAll([
        'ethusdt',
        'BTCUSDT',
        'bad symbol',
        'ETHUSDT',
        ' btcusdt',
      ]),
      ['ETHUSDT', 'BTCUSDT'],
    );
  });

  test('getSymbols cleans up stored symbols', () async {
    final storage = FakeWatchlistStorage(['btcusdt', 'BTCUSDT', '???']);

    expect(await WatchlistRepository(storage).getSymbols(), ['BTCUSDT']);
  });

  test('saveSymbols stores and returns the normalized list', () async {
    final storage = FakeWatchlistStorage();

    final saved = await WatchlistRepository(storage)
        .saveSymbols(['solusdt', 'SOLUSDT', 'ethusdt']);

    expect(saved, ['SOLUSDT', 'ETHUSDT']);
    expect(storage.symbols, saved);
  });

  test('saveSymbols surfaces write failures', () async {
    final storage = FakeWatchlistStorage()..failWrites = true;

    await expectLater(
      WatchlistRepository(storage).saveSymbols(['BTCUSDT']),
      throwsA(isA<StorageException>()),
    );
  });
}
