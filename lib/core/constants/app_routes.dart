abstract final class AppRoutes {
  static const marketPath = '/';
  static const marketName = 'market';

  static const watchlistPath = '/watchlist';
  static const watchlistName = 'watchlist';

  static const coinDetailsPath = '/coins/:symbol';
  static const coinDetailsName = 'coinDetails';
  static const coinSymbolParam = 'symbol';

  static String coinDetailsLocation(String symbol) =>
      '/coins/${Uri.encodeComponent(symbol)}';
}
