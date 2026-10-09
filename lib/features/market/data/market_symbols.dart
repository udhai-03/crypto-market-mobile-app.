/// Binance trading pairs shown on the Market screen.
///
/// Every entry must be a listed Binance symbol: a single unknown symbol makes
/// the whole multi-symbol ticker request fail with HTTP 400.
abstract final class MarketSymbols {
  static const tracked = <String>[
    'BTCUSDT',
    'ETHUSDT',
    'BNBUSDT',
    'SOLUSDT',
    'XRPUSDT',
    'DOGEUSDT',
    'ADAUSDT',
    'TRXUSDT',
    'AVAXUSDT',
    'LINKUSDT',
    'DOTUSDT',
    'LTCUSDT',
  ];

  /// The tracked symbol matching [raw] (case-insensitive), or null when
  /// [raw] is missing or not tracked.
  static String? resolve(String? raw) {
    final normalized = raw?.trim().toUpperCase();
    return tracked.contains(normalized) ? normalized : null;
  }
}
