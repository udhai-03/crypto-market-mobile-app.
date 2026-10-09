import 'package:crypto_market_mobile/features/market/data/models/binance_json.dart';

/// One record of Binance `GET /api/v3/klines`.
///
/// Klines are positional arrays, e.g.
/// `[1499040000000, "0.016", "0.8", "0.015", "0.0157", "148976.1",
///   1499644799999, "2434.19", 308, "1756.87", "28.46", "0"]`.
class BinanceKlineDto {
  const BinanceKlineDto({
    required this.openTime,
    required this.closeTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.quoteVolume,
  });

  /// Throws a [FormatException] when the record is not an array with the
  /// documented fields, or its values are missing, malformed or inconsistent.
  factory BinanceKlineDto.fromJson(Object? json) {
    if (json is! List<Object?> || json.length < _minimumFieldCount) {
      throw FormatException('Invalid Binance kline record', json);
    }

    final dto = BinanceKlineDto(
      openTime: BinanceJson.parseTimestampMs(json[_openTime], 'openTime'),
      open: BinanceJson.parseDecimal(json[_open], 'open'),
      high: BinanceJson.parseDecimal(json[_high], 'high'),
      low: BinanceJson.parseDecimal(json[_low], 'low'),
      close: BinanceJson.parseDecimal(json[_close], 'close'),
      volume: BinanceJson.parseDecimal(json[_volume], 'volume'),
      closeTime: BinanceJson.parseTimestampMs(json[_closeTime], 'closeTime'),
      quoteVolume: BinanceJson.parseDecimal(json[_quoteVolume], 'quoteVolume'),
    );

    if (dto.closeTime.isBefore(dto.openTime) || dto.high < dto.low) {
      throw FormatException('Inconsistent Binance kline record', json);
    }
    return dto;
  }

  static const _openTime = 0;
  static const _open = 1;
  static const _high = 2;
  static const _low = 3;
  static const _close = 4;
  static const _volume = 5;
  static const _closeTime = 6;
  static const _quoteVolume = 7;
  static const _minimumFieldCount = _quoteVolume + 1;

  final DateTime openTime;
  final DateTime closeTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final double quoteVolume;
}
