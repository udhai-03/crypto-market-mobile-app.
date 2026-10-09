/// Base and quote assets of a trading symbol, e.g. BTCUSDT → BTC / USDT.
class TradingPair {
  const TradingPair({required this.base, required this.quote});

  /// Splits [symbol] on a known quote asset; unknown quotes leave [quote]
  /// empty and keep the whole symbol as [base].
  factory TradingPair.fromSymbol(String symbol) {
    for (final quote in _quoteAssets) {
      if (symbol.length > quote.length && symbol.endsWith(quote)) {
        return TradingPair(
          base: symbol.substring(0, symbol.length - quote.length),
          quote: quote,
        );
      }
    }
    return TradingPair(base: symbol, quote: '');
  }

  static const _quoteAssets = ['FDUSD', 'USDT', 'USDC', 'BTC', 'ETH', 'BNB'];

  final String base;
  final String quote;

  String get displayName => quote.isEmpty ? base : '$base / $quote';
}
