import 'dart:convert';

/// Versioned JSON format of the stored watchlist:
/// `{"version": 1, "symbols": ["BTCUSDT", "ETHUSDT"]}`.
abstract final class WatchlistCodec {
  static const currentVersion = 1;

  static const _versionKey = 'version';
  static const _symbolsKey = 'symbols';

  static String encode(List<String> symbols) {
    return jsonEncode({_versionKey: currentVersion, _symbolsKey: symbols});
  }

  /// Throws a [FormatException] for malformed JSON, an unknown version, or
  /// a symbol list containing non-string entries.
  static List<String> decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Watchlist is not a JSON object', raw);
    }
    if (decoded[_versionKey] != currentVersion) {
      throw FormatException('Unsupported watchlist version', raw);
    }
    final symbols = decoded[_symbolsKey];
    if (symbols is! List<Object?> || symbols.any((item) => item is! String)) {
      throw FormatException('Watchlist symbols are not strings', raw);
    }
    return List<String>.unmodifiable(symbols.cast<String>());
  }
}
