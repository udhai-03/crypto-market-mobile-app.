abstract final class AppStrings {
  static const appName = 'Crypto Market';

  static const market = 'Market';
  static const watchlist = 'Watchlist';
  static const coinDetails = 'Coin Details';

  static const watchlistTitle = 'Watchlist';
  static const watchlistSubtitle = 'Your saved trading pairs';
  static const watchlistLoading = 'Loading your watchlist';
  static const watchlistEmptyTitle = 'Your watchlist is empty';
  static const watchlistEmptyMessage =
      'Tap the star on any market to keep it here.';
  static const browseMarkets = 'Browse markets';
  static const watchlistLoadErrorTitle = 'Watchlist unavailable';
  static const watchlistReadError = 'Could not load your saved pairs.';
  static const watchlistWriteError =
      'Could not update your watchlist. Please try again.';
  static const watchlistControlUnavailable = 'Watchlist unavailable';
  static const watchlistPriceUnavailable = 'Price unavailable right now';
  static const watchlistPriceLoading = 'Loading price';
  static const watchlistUnsupported = 'No longer available in this app';
  static String addToWatchlist(String symbol) => 'Add $symbol to watchlist';
  static String removeFromWatchlist(String symbol) =>
      'Remove $symbol from watchlist';
  static String watchlistStatusSemantics(String symbol, String status) =>
      '$symbol, $status';

  static const coinNotFoundTitle = 'Market not found';
  static const coinNotFoundMessage =
      'This trading pair is not tracked in the app.';
  static const backToMarkets = 'Back to markets';
  static const backTooltip = 'Back';

  static const priceUnavailable = 'Live price is unavailable right now.';
  static const statsTitle = '24h statistics';
  static const statHigh24h = '24h high';
  static const statLow24h = '24h low';
  static const statChange24h = '24h change';
  static String volumeIn(String asset) =>
      asset.isEmpty ? 'Volume' : 'Volume ($asset)';

  static const timeframeOneHour = '1H';
  static const timeframeFourHours = '4H';
  static const timeframeOneDay = '24H';
  static const timeframeSevenDays = '7D';
  static const timeframeThirtyDays = '30D';
  static const timeframeSelectorLabel = 'Chart timeframe';

  static const chartTitle = 'Price history';
  static const chartHistoricalNote =
      'Historical Binance candles, loaded when opened · not live';
  static const chartLoading = 'Loading price history';
  static const chartErrorTitle = 'Chart unavailable';
  static const chartEmptyTitle = 'No price history';
  static const chartEmptyMessage =
      'Not enough price history for this timeframe yet.';
  static String chartRangeCaption(String timeframe) => 'Change over $timeframe';
  static String chartRangeDetails({
    required String high,
    required String low,
  }) => 'H $high · L $low';
  static String chartCandleDetails({
    required String open,
    required String high,
    required String low,
  }) => 'O $open · H $high · L $low';
  static String chartSemantics({
    required String timeframe,
    required String from,
    required String to,
    required String change,
  }) => 'Price chart for $timeframe, from $from to $to, change $change';

  static const marketsTitle = 'Markets';
  static const marketsSubtitle = 'Binance USDT pairs tracked in this app';
  static const marketsLoading = 'Loading markets';

  static const liveStatusLive = 'Live';
  static const liveStatusConnecting = 'Connecting…';
  static const liveStatusReconnecting = 'Reconnecting…';
  static const liveStatusOffline = 'Offline';

  static String liveStatusSemantics(String status) =>
      'Live price updates: $status';

  static const summaryTitle = 'Market pulse';
  static const summaryCaption = 'Tracked Binance pairs · last 24h';
  static const statTrackedPairs = 'Pairs';
  static const statGainers = 'Gainers';
  static const statLosers = 'Losers';
  static const statAverageChange = 'Average 24h change';
  static const statTopGainer = 'Top gainer';
  static const statTopLoser = 'Top loser';
  static const statTopVolume = 'Top volume';

  static const searchHint = 'Search coins, e.g. BTC';
  static const clearSearch = 'Clear search';

  static const filterAll = 'All';
  static const filterGainers = 'Gainers';
  static const filterLosers = 'Losers';

  static const sortTooltip = 'Sort markets';
  static const sortDefault = 'Default';
  static const sortPriceHighToLow = 'Price: High → Low';
  static const sortPriceLowToHigh = 'Price: Low → High';
  static const sortChangeHighToLow = '24h change: High → Low';
  static const sortChangeLowToHigh = '24h change: Low → High';
  static const sortVolumeHighToLow = '24h quote volume: High → Low';

  static const change24hLabel = '24h';
  static const volumeLabel = '24h vol';
  static String shortVolume(String amount) => 'Vol $amount';
  static String amountIn(String amount, String asset) =>
      asset.isEmpty ? amount : '$amount $asset';

  static const marketEmptyTitle = 'No market data';
  static const marketEmpty = 'No market data available right now.';
  static const noResultsTitle = 'No markets found';
  static const noResultsMessage = 'Try a different search term or filter.';
  static const clearSearchAndFilter = 'Clear search & filter';
  static const errorTitle = 'Something went wrong';
  static const marketRefreshFailed = 'Could not refresh market data.';
  static const retry = 'Retry';
  static const refresh = 'Refresh';

  static const noConnectionError =
      'No internet connection. Check your network and try again.';
  static const timeoutError = 'The request timed out. Please try again.';
  static const serverError =
      'The market data service returned an error. Please try again later.';
  static const invalidResponseError =
      'Received unexpected data from the market service.';
  static const unexpectedError = 'Something went wrong. Please try again.';

  static String pairCount(int count) => count == 1 ? '1 pair' : '$count pairs';

  static String tickerSemantics({
    required String symbol,
    required String price,
    required String change,
    required String volume,
  }) {
    return '$symbol, price $price, 24 hour change $change, volume $volume';
  }
}
