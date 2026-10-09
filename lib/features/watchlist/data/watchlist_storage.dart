import 'package:shared_preferences/shared_preferences.dart';

import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/features/watchlist/data/watchlist_codec.dart';

/// Persists the watchlist's symbols on the device.
abstract interface class WatchlistStorage {
  /// Saved symbols in their stored order; empty when nothing was saved.
  ///
  /// Throws a [StorageException] when storage cannot be read or the stored
  /// data is unreadable. Unreadable data is left untouched.
  Future<List<String>> readSymbols();

  /// Replaces the saved symbols. Throws a [StorageException] on failure.
  Future<void> writeSymbols(List<String> symbols);
}

class SharedPreferencesWatchlistStorage implements WatchlistStorage {
  const SharedPreferencesWatchlistStorage(this._preferences);

  final SharedPreferencesAsync _preferences;

  static const storageKey = 'watchlist';

  @override
  Future<List<String>> readSymbols() async {
    final String? raw;
    try {
      raw = await _preferences.getString(storageKey);
    } on Object {
      throw const StorageException(AppStrings.watchlistReadError);
    }
    if (raw == null) return const [];

    try {
      return WatchlistCodec.decode(raw);
    } on FormatException {
      throw const StorageException(AppStrings.watchlistReadError);
    }
  }

  @override
  Future<void> writeSymbols(List<String> symbols) async {
    try {
      await _preferences.setString(storageKey, WatchlistCodec.encode(symbols));
    } on Object {
      throw const StorageException(AppStrings.watchlistWriteError);
    }
  }
}
