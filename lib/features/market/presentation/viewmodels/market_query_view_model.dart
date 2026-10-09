import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/features/market/presentation/models/market_query.dart';

final marketQueryProvider = NotifierProvider<MarketQueryViewModel, MarketQuery>(
  MarketQueryViewModel.new,
);

/// Owns local search/filter/sort state. Changes never trigger a network call.
class MarketQueryViewModel extends Notifier<MarketQuery> {
  @override
  MarketQuery build() => const MarketQuery();

  void updateSearch(String searchText) {
    state = state.copyWith(searchText: searchText);
  }

  void selectFilter(MarketFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void selectSort(MarketSort sort) {
    state = state.copyWith(sort: sort);
  }

  void clearSearchAndFilter() {
    state = MarketQuery(sort: state.sort);
  }
}
