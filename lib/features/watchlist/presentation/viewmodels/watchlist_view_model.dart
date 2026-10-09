import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/features/watchlist/data/watchlist_repository.dart';
import 'package:crypto_market_mobile/features/watchlist/providers/watchlist_providers.dart';

/// Saved watchlist symbols, oldest first. Independent of market data.
final watchlistViewModelProvider =
    AsyncNotifierProvider<WatchlistViewModel, List<String>>(
      WatchlistViewModel.new,
      retry: _retryOnlyOnUserRequest,
    );

Duration? _retryOnlyOnUserRequest(int retryCount, Object error) => null;

/// Whether [symbol] is saved; null while the watchlist is loading or could
/// not be read, so controls can be disabled instead of guessing.
final watchlistMembershipProvider = Provider.autoDispose.family<bool?, String>((
  ref,
  symbol,
) {
  return ref.watch(
    watchlistViewModelProvider.select((state) => state.value?.contains(symbol)),
  );
});

class WatchlistViewModel extends AsyncNotifier<List<String>> {
  /// Serializes changes so rapid taps cannot overwrite each other's writes.
  Future<void> _pendingChange = Future.value();

  @override
  Future<List<String>> build() => _repository.getSymbols();

  /// Rereads storage, e.g. after a failed initial load.
  Future<void> reload() async {
    state = const AsyncLoading<List<String>>();
    state = await AsyncValue.guard(_repository.getSymbols);
  }

  /// Returns false when nothing was saved: the watchlist is not loaded,
  /// [symbol] is invalid, or storage failed. Adding a saved symbol is a
  /// successful no-op.
  Future<bool> add(String symbol) => _change(symbol, _added);

  /// Returns false when the change could not be saved. Removing an absent
  /// symbol is a successful no-op.
  Future<bool> remove(String symbol) => _change(symbol, _removed);

  /// Adds or removes [symbol] based on the state after earlier queued
  /// changes, so repeated taps alternate correctly.
  Future<bool> toggle(String symbol) {
    return _change(
      symbol,
      (symbols, normalized) => symbols.contains(normalized)
          ? _removed(symbols, normalized)
          : _added(symbols, normalized),
    );
  }

  static List<String> _added(List<String> symbols, String symbol) {
    return symbols.contains(symbol) ? symbols : [...symbols, symbol];
  }

  static List<String> _removed(List<String> symbols, String symbol) {
    return [
      for (final saved in symbols)
        if (saved != symbol) saved,
    ];
  }

  WatchlistRepository get _repository => ref.read(watchlistRepositoryProvider);

  Future<bool> _change(
    String symbol,
    List<String> Function(List<String> symbols, String normalized) update,
  ) {
    final result = _pendingChange.then((_) async {
      final normalized = WatchlistRepository.normalize(symbol);
      final current = state.value;
      if (normalized == null || current == null || state.hasError) {
        return false;
      }

      final next = update(current, normalized);
      if (listEquals(next, current)) return true;

      try {
        state = AsyncData(await _repository.saveSymbols(next));
        return true;
      } on AppException {
        return false;
      }
    });
    _pendingChange = result.then((_) {}, onError: (_) {});
    return result;
  }
}
