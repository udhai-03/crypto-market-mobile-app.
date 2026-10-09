import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/features/market/data/models/binance_ticker_dto.dart';

void main() {
  Map<String, dynamic> tickerJson({
    Object? lastPrice = '67250.12000000',
    Object? quoteVolume = '1706757994.77410000',
    Object? closeTime = 1791544672007,
  }) {
    return {
      'symbol': 'BTCUSDT',
      'lastPrice': lastPrice,
      'priceChange': '-2613.30000000',
      'priceChangePercent': '-3.137',
      'highPrice': '68000.00000000',
      'lowPrice': '66000.50000000',
      'volume': '20744.07841000',
      'quoteVolume': quoteVolume,
      'closeTime': closeTime,
    };
  }

  test('parses Binance numeric strings into doubles', () {
    final dto = BinanceTickerDto.fromJson(tickerJson());

    expect(dto.symbol, 'BTCUSDT');
    expect(dto.lastPrice, 67250.12);
    expect(dto.priceChange, -2613.3);
    expect(dto.priceChangePercent, -3.137);
    expect(dto.quoteVolume, 1706757994.7741);
    expect(
      dto.closeTime,
      DateTime.fromMillisecondsSinceEpoch(1791544672007, isUtc: true),
    );
  });

  test('maps to the domain model', () {
    final ticker = BinanceTickerDto.fromJson(tickerJson()).toDomain();

    expect(ticker.symbol, 'BTCUSDT');
    expect(ticker.lastPrice, 67250.12);
    expect(ticker.lowPrice, 66000.5);
    expect(ticker.updatedAt.millisecondsSinceEpoch, 1791544672007);
  });

  test('accepts a zero price and zero volume', () {
    final dto = BinanceTickerDto.fromJson(
      tickerJson(lastPrice: '0.00000000', quoteVolume: '0'),
    );

    expect(dto.lastPrice, 0);
    expect(dto.quoteVolume, 0);
  });

  for (final (description, json) in [
    ('malformed numbers', tickerJson(lastPrice: 'abc')),
    ('missing fields', tickerJson(lastPrice: null)),
    ('non-finite numbers', tickerJson(lastPrice: 'NaN')),
    ('negative prices', tickerJson(lastPrice: '-1.5')),
    ('negative volumes', tickerJson(quoteVolume: '-10')),
    ('missing close time', tickerJson(closeTime: null)),
    ('non-integer close time', tickerJson(closeTime: '1791544672007')),
  ]) {
    test('throws FormatException for $description', () {
      expect(() => BinanceTickerDto.fromJson(json), throwsFormatException);
    });
  }
}
