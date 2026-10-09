import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:crypto_market_mobile/features/watchlist/data/watchlist_repository.dart';
import 'package:crypto_market_mobile/features/watchlist/data/watchlist_storage.dart';

final watchlistStorageProvider = Provider<WatchlistStorage>((ref) {
  return SharedPreferencesWatchlistStorage(SharedPreferencesAsync());
});

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return WatchlistRepository(ref.watch(watchlistStorageProvider));
});
