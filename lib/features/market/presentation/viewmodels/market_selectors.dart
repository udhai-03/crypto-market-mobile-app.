import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/features/market/domain/models/live_connection_status.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/market_summary.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_query_view_model.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_view_model.dart';
import 'package:crypto_market_mobile/features/market/providers/market_providers.dart';

/// Last loaded tickers, kept during refreshes and failed refreshes.
final _loadedTickersProvider = Provider<List<MarketTicker>>((ref) {
  return ref.watch(marketViewModelProvider.select((state) => state.value)) ??
      const [];
});

/// Loaded tickers after applying the current search, filter, and sort.
final visibleMarketTickersProvider = Provider<List<MarketTicker>>((ref) {
  final tickers = ref.watch(_loadedTickersProvider);
  return ref.watch(marketQueryProvider).apply(tickers);
});

/// Summary of all loaded tickers, independent of search and filter.
final marketSummaryProvider = Provider<MarketSummary>((ref) {
  return MarketSummary.fromTickers(ref.watch(_loadedTickersProvider));
});

final _connectionStatusStreamProvider = StreamProvider<LiveConnectionStatus>((
  ref,
) {
  return ref.watch(marketRepositoryProvider).watchConnectionStatus();
});

final marketConnectionStatusProvider = Provider<LiveConnectionStatus>((ref) {
  return ref.watch(_connectionStatusStreamProvider).value ??
      LiveConnectionStatus.connecting;
});
