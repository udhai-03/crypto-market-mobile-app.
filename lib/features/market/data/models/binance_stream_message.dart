import 'dart:convert';

import 'package:crypto_market_mobile/features/market/data/models/binance_json.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker_update.dart';

/// A message received on a Binance combined stream (`/stream?streams=...`).
///
/// Combined-stream frames wrap each event: `{"stream": "...", "data": {...}}`.
sealed class BinanceStreamMessage {
  const BinanceStreamMessage();

  static const _tickerEventType = '24hrTicker';
  static const _serverShutdownEventType = 'serverShutdown';

  /// Throws a [FormatException] for malformed JSON, an unexpected wrapper or
  /// event type, or a ticker event with missing/invalid fields.
  static BinanceStreamMessage parse(Object? frame) {
    if (frame is! String) {
      throw FormatException('Expected a text frame', frame);
    }

    final decoded = jsonDecode(frame);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected a JSON object', frame);
    }
    final data = decoded['data'];
    if (decoded['stream'] is! String || data is! Map<String, dynamic>) {
      throw FormatException('Expected a combined-stream wrapper', frame);
    }

    return switch (data['e']) {
      _tickerEventType => BinanceTickerEvent.fromJson(data),
      _serverShutdownEventType => const BinanceServerShutdown(),
      final other => throw FormatException('Unsupported event type', other),
    };
  }
}

/// Payload of the `<symbol>@ticker` stream (24h rolling window statistics).
final class BinanceTickerEvent extends BinanceStreamMessage {
  const BinanceTickerEvent({
    required this.symbol,
    required this.lastPrice,
    required this.priceChange,
    required this.priceChangePercent,
    required this.highPrice,
    required this.lowPrice,
    required this.volume,
    required this.quoteVolume,
    required this.closeTime,
  });

  factory BinanceTickerEvent.fromJson(Map<String, dynamic> json) {
    return BinanceTickerEvent(
      symbol: BinanceJson.readString(json, 's'),
      lastPrice: BinanceJson.readNonNegativeDecimal(json, 'c'),
      priceChange: BinanceJson.readDecimal(json, 'p'),
      priceChangePercent: BinanceJson.readDecimal(json, 'P'),
      highPrice: BinanceJson.readNonNegativeDecimal(json, 'h'),
      lowPrice: BinanceJson.readNonNegativeDecimal(json, 'l'),
      volume: BinanceJson.readNonNegativeDecimal(json, 'v'),
      quoteVolume: BinanceJson.readNonNegativeDecimal(json, 'q'),
      closeTime: BinanceJson.readTimestampMs(json, 'C'),
    );
  }

  final String symbol;
  final double lastPrice;
  final double priceChange;
  final double priceChangePercent;
  final double highPrice;
  final double lowPrice;
  final double volume;
  final double quoteVolume;

  /// Statistics close time, comparable with the REST ticker's `closeTime`.
  final DateTime closeTime;

  MarketTickerUpdate toDomain() {
    return MarketTickerUpdate(
      symbol: symbol,
      lastPrice: lastPrice,
      priceChange: priceChange,
      priceChangePercent: priceChangePercent,
      highPrice: highPrice,
      lowPrice: lowPrice,
      volume: volume,
      quoteVolume: quoteVolume,
      updatedAt: closeTime,
    );
  }
}

/// Binance is about to close the connection; a new one should be opened.
final class BinanceServerShutdown extends BinanceStreamMessage {
  const BinanceServerShutdown();
}
