import 'dart:async';

import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/features/watchlist/data/watchlist_storage.dart';

/// In-memory watchlist storage with switchable failures.
class FakeWatchlistStorage implements WatchlistStorage {
  FakeWatchlistStorage([List<String> initial = const []])
    : symbols = List.of(initial);

  List<String> symbols;
  bool failReads = false;
  bool failWrites = false;
  int readCount = 0;
  int writeCount = 0;

  /// When set, reads wait for it to complete.
  Completer<void>? readGate;

  @override
  Future<List<String>> readSymbols() async {
    readCount++;
    await readGate?.future;
    if (failReads) {
      throw const StorageException(AppStrings.watchlistReadError);
    }
    return List.unmodifiable(symbols);
  }

  @override
  Future<void> writeSymbols(List<String> symbols) async {
    if (failWrites) {
      throw const StorageException(AppStrings.watchlistWriteError);
    }
    writeCount++;
    this.symbols = List.of(symbols);
  }
}
