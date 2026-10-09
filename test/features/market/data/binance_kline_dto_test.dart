import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/features/market/data/models/binance_kline_dto.dart';

import '../../../helpers/kline_fixtures.dart';

void main() {
  test('parses a documented Binance kline array', () {
    final kline = BinanceKlineDto.fromJson(klineRecord());

    expect(kline.open, 82704);
    expect(kline.high, 82704.01);
    expect(kline.low, 82550);
    expect(kline.close, 82658.01);
    expect(kline.volume, 283.97863);
    expect(kline.quoteVolume, 23462671.9723081);
  });

  test('reads timestamps as UTC milliseconds, not seconds', () {
    final kline = BinanceKlineDto.fromJson(klineRecord());

    expect(kline.openTime, DateTime.utc(2026, 10, 9, 9));
    expect(kline.openTime.isUtc, isTrue);
    expect(kline.closeTime, DateTime.utc(2026, 10, 9, 9, 59, 59, 999));
  });

  test('accepts numeric values encoded as numbers', () {
    final kline = BinanceKlineDto.fromJson(klineRecord(open: 1.5, close: 2));

    expect(kline.open, 1.5);
    expect(kline.close, 2);
  });

  test('rejects records that are not arrays or are too short', () {
    final malformed = <Object?>[
      null,
      'kline',
      {'openTime': 1791536400000},
      klineRecord().sublist(0, 7),
    ];

    for (final record in malformed) {
      expect(
        () => BinanceKlineDto.fromJson(record),
        throwsFormatException,
        reason: '$record',
      );
    }
  });

  test('rejects missing or invalid values', () {
    final invalid = [
      klineRecord(open: null),
      klineRecord(close: 'not-a-number'),
      klineRecord(high: 'NaN'),
      klineRecord(volume: true),
      klineRecord(openTime: '1791536400000'),
      klineRecord(openTime: -1),
      klineRecord(closeTime: 1.5),
    ];

    for (final record in invalid) {
      expect(
        () => BinanceKlineDto.fromJson(record),
        throwsFormatException,
        reason: '$record',
      );
    }
  });

  test('rejects inconsistent records', () {
    expect(
      () => BinanceKlineDto.fromJson(
        klineRecord(openTime: 1791539999999, closeTime: 1791536400000),
      ),
      throwsFormatException,
    );
    expect(
      () => BinanceKlineDto.fromJson(klineRecord(high: '1', low: '2')),
      throwsFormatException,
    );
  });
}
