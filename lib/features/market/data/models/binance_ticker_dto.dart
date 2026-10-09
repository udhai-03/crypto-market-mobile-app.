import 'package:crypto_market_mobile/features/market/data/models/binance_json.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';

/// Response item of Binance `GET /api/v3/ticker/24hr`.
///
/// Binance encodes decimal values as strings, e.g. `"lastPrice": "67250.12"`.
class BinanceTickerDto {
  const BinanceTickerDto({
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

  /// Throws a [FormatException] when a field is missing or malformed, or a
  /// price or volume is negative.
  factory BinanceTickerDto.fromJson(Map<String, dynamic> json) {
    return BinanceTickerDto(
      symbol: BinanceJson.readString(json, 'symbol'),
      lastPrice: BinanceJson.readNonNegativeDecimal(json, 'lastPrice'),
      priceChange: BinanceJson.readDecimal(json, 'priceChange'),
      priceChangePercent: BinanceJson.readDecimal(json, 'priceChangePercent'),
      highPrice: BinanceJson.readNonNegativeDecimal(json, 'highPrice'),
      lowPrice: BinanceJson.readNonNegativeDecimal(json, 'lowPrice'),
      volume: BinanceJson.readNonNegativeDecimal(json, 'volume'),
      quoteVolume: BinanceJson.readNonNegativeDecimal(json, 'quoteVolume'),
      closeTime: BinanceJson.readTimestampMs(json, 'closeTime'),
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

  /// End of the rolling 24h window these statistics describe.
  final DateTime closeTime;

  MarketTicker toDomain() {
    return MarketTicker(
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
