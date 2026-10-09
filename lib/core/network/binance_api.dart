abstract final class BinanceApi {
  static const baseUrl = 'https://api.binance.com';

  static const ticker24hPath = '/api/v3/ticker/24hr';
  static const symbolsQueryParam = 'symbols';

  static const klinesPath = '/api/v3/klines';
  static const symbolQueryParam = 'symbol';
  static const intervalQueryParam = 'interval';
  static const limitQueryParam = 'limit';

  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 15);

  static const webSocketBaseUrl = 'wss://stream.binance.com:9443';
  static const combinedStreamPath = '/stream';
  static const streamsQueryParam = 'streams';
  static const tickerStreamSuffix = '@ticker';
  static const maxStreamsPerConnection = 1024;

  /// Binance pings every 20s; our own pings detect silently dropped
  /// connections (e.g. after a mobile network switch).
  static const webSocketPingInterval = Duration(seconds: 20);

  /// Combined-stream URL, e.g. `.../stream?streams=btcusdt@ticker/ethusdt@ticker`.
  static Uri tickerStreamUri(List<String> symbols) {
    assert(symbols.isNotEmpty && symbols.length <= maxStreamsPerConnection);
    final streams = symbols
        .map((symbol) => '${symbol.toLowerCase()}$tickerStreamSuffix')
        .join('/');
    return Uri.parse(
      '$webSocketBaseUrl$combinedStreamPath?$streamsQueryParam=$streams',
    );
  }
}
