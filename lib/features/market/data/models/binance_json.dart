/// Readers for Binance JSON payloads, which encode decimals as strings.
///
/// All readers throw a [FormatException] when the value is missing or
/// malformed.
abstract final class BinanceJson {
  static String readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return value;
    throw FormatException('Invalid "$key" in Binance payload', value);
  }

  static double readDecimal(Map<String, dynamic> json, String key) {
    return parseDecimal(json[key], key);
  }

  /// For prices and volumes, which can never be negative.
  static double readNonNegativeDecimal(Map<String, dynamic> json, String key) {
    final value = readDecimal(json, key);
    if (value >= 0) return value;
    throw FormatException('Negative "$key" in Binance payload', value);
  }

  static DateTime readTimestampMs(Map<String, dynamic> json, String key) {
    return parseTimestampMs(json[key], key);
  }

  static double parseDecimal(Object? value, String field) {
    final parsed = switch (value) {
      final String text => double.tryParse(text),
      final num number => number.toDouble(),
      _ => null,
    };
    if (parsed != null && parsed.isFinite) return parsed;
    throw FormatException('Invalid "$field" in Binance payload', value);
  }

  /// Binance timestamps are integer milliseconds since the Unix epoch (UTC).
  static DateTime parseTimestampMs(Object? value, String field) {
    if (value is int && value >= 0) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
    }
    throw FormatException('Invalid "$field" in Binance payload', value);
  }
}
