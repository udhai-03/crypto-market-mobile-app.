import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/features/watchlist/data/watchlist_codec.dart';

void main() {
  test('round-trips symbols in order', () {
    const symbols = ['ETHUSDT', 'BTCUSDT'];

    expect(WatchlistCodec.decode(WatchlistCodec.encode(symbols)), symbols);
  });

  test('encodes a versioned JSON object', () {
    expect(
      WatchlistCodec.encode(['BTCUSDT']),
      '{"version":1,"symbols":["BTCUSDT"]}',
    );
  });

  test('decodes an empty list', () {
    expect(WatchlistCodec.decode('{"version":1,"symbols":[]}'), isEmpty);
  });

  for (final (description, raw) in [
    ('malformed JSON', '{"version":1,'),
    ('a non-object', '["BTCUSDT"]'),
    ('an unknown version', '{"version":2,"symbols":["BTCUSDT"]}'),
    ('a missing symbol list', '{"version":1}'),
    ('non-string symbols', '{"version":1,"symbols":["BTCUSDT",42]}'),
  ]) {
    test('rejects $description', () {
      expect(() => WatchlistCodec.decode(raw), throwsFormatException);
    });
  }
}
