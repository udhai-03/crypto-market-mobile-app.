import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/features/market/data/models/binance_stream_message.dart';

import '../../../helpers/fake_web_socket.dart';

void main() {
  group('BinanceStreamMessage.parse', () {
    test('parses a combined-stream ticker event', () {
      final message = BinanceStreamMessage.parse(
        tickerFrame('BTCUSDT', lastPrice: '67250.12'),
      );

      expect(message, isA<BinanceTickerEvent>());
      final update = (message as BinanceTickerEvent).toDomain();
      expect(update.symbol, 'BTCUSDT');
      expect(update.lastPrice, 67250.12);
      expect(update.priceChange, 1.25);
      expect(update.priceChangePercent, 2.5);
      expect(update.highPrice, 110);
      expect(update.lowPrice, 90);
      expect(update.volume, 1000);
      expect(update.quoteVolume, 100500);
      expect(update.updatedAt.millisecondsSinceEpoch, 1672515782136);
    });

    test('recognises the server shutdown event', () {
      final frame = jsonEncode({
        'stream': '!serverShutdown',
        'data': {'e': 'serverShutdown', 'E': 1770123456789},
      });

      expect(BinanceStreamMessage.parse(frame), isA<BinanceServerShutdown>());
    });

    test('rejects malformed JSON', () {
      expect(
        () => BinanceStreamMessage.parse('{"stream": '),
        throwsFormatException,
      );
    });

    test('rejects non-text frames', () {
      expect(
        () => BinanceStreamMessage.parse(const [1, 2, 3]),
        throwsFormatException,
      );
    });

    test('rejects payloads without the combined-stream wrapper', () {
      final rawEvent = jsonEncode({'e': '24hrTicker', 's': 'BTCUSDT'});
      final listPayload = jsonEncode([1, 2]);
      final dataNotObject = jsonEncode({'stream': 'x', 'data': 'oops'});

      for (final frame in [rawEvent, listPayload, dataNotObject]) {
        expect(
          () => BinanceStreamMessage.parse(frame),
          throwsFormatException,
          reason: frame,
        );
      }
    });

    test('rejects unsupported event types', () {
      final frame = jsonEncode({
        'stream': 'btcusdt@trade',
        'data': {'e': 'trade', 's': 'BTCUSDT'},
      });

      expect(() => BinanceStreamMessage.parse(frame), throwsFormatException);
    });

    test('rejects ticker events with missing or invalid fields', () {
      Map<String, dynamic> wrapper() =>
          jsonDecode(tickerFrame('BTCUSDT')) as Map<String, dynamic>;

      final missingPrice = wrapper();
      (missingPrice['data'] as Map<String, dynamic>).remove('c');
      final invalidVolume = wrapper();
      (invalidVolume['data'] as Map<String, dynamic>)['q'] = 'n/a';
      final negativePrice = wrapper();
      (negativePrice['data'] as Map<String, dynamic>)['c'] = '-100';
      final missingCloseTime = wrapper();
      (missingCloseTime['data'] as Map<String, dynamic>).remove('C');

      for (final frame in [
        missingPrice,
        invalidVolume,
        negativePrice,
        missingCloseTime,
      ]) {
        expect(
          () => BinanceStreamMessage.parse(jsonEncode(frame)),
          throwsFormatException,
        );
      }
    });
  });
}
