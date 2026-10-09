import 'package:crypto_market_mobile/features/watchlist/data/watchlist_storage.dart';

/// Normalizes watchlist symbols on the way in and out of storage.
class WatchlistRepository {
  const WatchlistRepository(this._storage);

  final WatchlistStorage _storage;

  static final _symbolPattern = RegExp(r'^[A-Z0-9]{2,30}$');

  /// Upper-cased, trimmed [raw], or null when it is not a valid symbol.
  static String? normalize(String raw) {
    final symbol = raw.trim().toUpperCase();
    return _symbolPattern.hasMatch(symbol) ? symbol : null;
  }

  /// Valid, normalized symbols in first-seen order without duplicates.
  static List<String> normalizeAll(Iterable<String> symbols) {
    final unique = <String>{for (final raw in symbols) ?normalize(raw)};
    return List.unmodifiable(unique);
  }

  /// Throws a `StorageException` when the watchlist cannot be read.
  Future<List<String>> getSymbols() async {
    return normalizeAll(await _storage.readSymbols());
  }

  /// Saves [symbols] and returns exactly what was stored.
  /// Throws a `StorageException` when the write fails.
  Future<List<String>> saveSymbols(List<String> symbols) async {
    final normalized = normalizeAll(symbols);
    await _storage.writeSymbols(normalized);
    return normalized;
  }
}
