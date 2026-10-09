import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker_update.dart';
import 'package:crypto_market_mobile/features/market/providers/market_providers.dart';

final marketViewModelProvider =
    AsyncNotifierProvider<MarketViewModel, List<MarketTicker>>(
      MarketViewModel.new,
      retry: _retryOnlyOnUserRequest,
    );

Duration? _retryOnlyOnUserRequest(int retryCount, Object error) => null;

/// Market tickers loaded from the REST snapshot and kept current by live
/// updates while the provider is alive and live updates are not paused.
///
/// Every ticker carries the time its statistics were computed, so when a
/// snapshot and live updates overlap the newest values always win.
class MarketViewModel extends AsyncNotifier<List<MarketTicker>> {
  StreamSubscription<MarketTickerUpdate>? _liveUpdates;

  /// Newest live update per symbol received while a snapshot is loading;
  /// bounded by the number of streamed symbols.
  final _pendingUpdates = <String, MarketTickerUpdate>{};

  /// Identifies the latest refresh so an older, slower one cannot replace
  /// its result.
  int _refreshId = 0;

  @override
  Future<List<MarketTicker>> build() {
    ref.onDispose(pauseLiveUpdates);
    resumeLiveUpdates();
    return _loadMarketData();
  }

  /// Reloads market data while keeping the last loaded list available, so
  /// the view can keep showing it during a pull-to-refresh.
  Future<void> refresh() async {
    final refreshId = ++_refreshId;
    state = const AsyncLoading<List<MarketTicker>>();
    final result = await AsyncValue.guard(_loadMarketData);
    if (refreshId == _refreshId) state = result;
  }

  /// Stops live updates (and closes the live connection), e.g. while the
  /// app is in the background. The last values stay visible.
  void pauseLiveUpdates() {
    unawaited(_liveUpdates?.cancel());
    _liveUpdates = null;
  }

  void resumeLiveUpdates() {
    _liveUpdates ??= ref
        .read(marketRepositoryProvider)
        .watchTickerUpdates()
        .listen(_applyUpdate);
  }

  Future<List<MarketTicker>> _loadMarketData() async {
    try {
      final snapshot = await ref
          .read(marketRepositoryProvider)
          .getMarketTickers();
      return _keepNewest(snapshot);
    } finally {
      _pendingUpdates.clear();
    }
  }

  /// Snapshot tickers, except where the currently shown ticker or an
  /// update received during the load is newer than the snapshot.
  List<MarketTicker> _keepNewest(List<MarketTicker> snapshot) {
    final shown = {
      for (final ticker in state.value ?? const <MarketTicker>[])
        ticker.symbol: ticker,
    };
    return List.unmodifiable([
      for (final ticker in snapshot)
        _newest(ticker, shown[ticker.symbol], _pendingUpdates[ticker.symbol]),
    ]);
  }

  static MarketTicker _newest(
    MarketTicker snapshot,
    MarketTicker? shown,
    MarketTickerUpdate? pending,
  ) {
    var newest = snapshot;
    if (shown != null && shown.updatedAt.isAfter(newest.updatedAt)) {
      newest = shown;
    }
    if (pending != null && pending.updatedAt.isAfter(newest.updatedAt)) {
      newest = newest.applyUpdate(pending);
    }
    return newest;
  }

  void _applyUpdate(MarketTickerUpdate update) {
    final tickers = state.value;
    if (state.isLoading || tickers == null) {
      final pending = _pendingUpdates[update.symbol];
      if (pending == null || !update.updatedAt.isBefore(pending.updatedAt)) {
        _pendingUpdates[update.symbol] = update;
      }
      return;
    }

    final index = tickers.indexWhere(
      (ticker) => ticker.symbol == update.symbol,
    );
    if (index == -1 || update.updatedAt.isBefore(tickers[index].updatedAt)) {
      return;
    }

    final updated = [...tickers];
    updated[index] = tickers[index].applyUpdate(update);
    state = AsyncData(List.unmodifiable(updated));
  }
}
