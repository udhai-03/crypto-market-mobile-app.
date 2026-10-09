import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';

enum MarketFilter {
  all(AppStrings.filterAll),
  gainers(AppStrings.filterGainers),
  losers(AppStrings.filterLosers);

  const MarketFilter(this.label);

  final String label;

  bool matches(MarketTicker ticker) {
    return switch (this) {
      all => true,
      gainers => ticker.priceChangePercent > 0,
      losers => ticker.priceChangePercent < 0,
    };
  }
}

enum MarketSort {
  defaultOrder(AppStrings.sortDefault),
  priceHighToLow(AppStrings.sortPriceHighToLow),
  priceLowToHigh(AppStrings.sortPriceLowToHigh),
  changeHighToLow(AppStrings.sortChangeHighToLow),
  changeLowToHigh(AppStrings.sortChangeLowToHigh),
  volumeHighToLow(AppStrings.sortVolumeHighToLow);

  const MarketSort(this.label);

  final String label;

  /// Returns null for [defaultOrder], which keeps the API order.
  Comparator<MarketTicker>? get comparator {
    return switch (this) {
      defaultOrder => null,
      priceHighToLow => (a, b) => b.lastPrice.compareTo(a.lastPrice),
      priceLowToHigh => (a, b) => a.lastPrice.compareTo(b.lastPrice),
      changeHighToLow => (a, b) => b.priceChangePercent.compareTo(
        a.priceChangePercent,
      ),
      changeLowToHigh => (a, b) => a.priceChangePercent.compareTo(
        b.priceChangePercent,
      ),
      volumeHighToLow => (a, b) => b.quoteVolume.compareTo(a.quoteVolume),
    };
  }
}

/// Local search, filter, and sort selection for the market list.
class MarketQuery {
  const MarketQuery({
    this.searchText = '',
    this.filter = MarketFilter.all,
    this.sort = MarketSort.defaultOrder,
  });

  final String searchText;
  final MarketFilter filter;
  final MarketSort sort;

  bool get hasSearchOrFilter =>
      searchText.trim().isNotEmpty || filter != MarketFilter.all;

  MarketQuery copyWith({
    String? searchText,
    MarketFilter? filter,
    MarketSort? sort,
  }) {
    return MarketQuery(
      searchText: searchText ?? this.searchText,
      filter: filter ?? this.filter,
      sort: sort ?? this.sort,
    );
  }

  /// Returns a new list; [tickers] is never modified.
  List<MarketTicker> apply(List<MarketTicker> tickers) {
    final normalizedSearch = searchText.trim().toUpperCase();
    final matches = tickers
        .where(
          (ticker) =>
              filter.matches(ticker) &&
              ticker.symbol.toUpperCase().contains(normalizedSearch),
        )
        .toList();

    final comparator = sort.comparator;
    if (comparator != null) {
      matches.sort((a, b) {
        final result = comparator(a, b);
        return result != 0 ? result : a.symbol.compareTo(b.symbol);
      });
    }
    return List.unmodifiable(matches);
  }

  @override
  bool operator ==(Object other) {
    return other is MarketQuery &&
        other.searchText == searchText &&
        other.filter == filter &&
        other.sort == sort;
  }

  @override
  int get hashCode => Object.hash(searchText, filter, sort);
}
