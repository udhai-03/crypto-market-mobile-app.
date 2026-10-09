import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/features/market/data/market_symbols.dart';
import 'package:crypto_market_mobile/features/market/domain/models/trading_pair.dart';

void main() {
  test('splits symbols on known quote assets', () {
    final pair = TradingPair.fromSymbol('DOGEUSDT');

    expect(pair.base, 'DOGE');
    expect(pair.quote, 'USDT');
    expect(pair.displayName, 'DOGE / USDT');
    expect(TradingPair.fromSymbol('ETHBTC').displayName, 'ETH / BTC');
  });

  test('keeps unknown symbols whole', () {
    final pair = TradingPair.fromSymbol('USDT');

    expect(pair.base, 'USDT');
    expect(pair.quote, isEmpty);
    expect(pair.displayName, 'USDT');
  });

  test('every tracked symbol has a base and quote asset', () {
    for (final symbol in MarketSymbols.tracked) {
      final pair = TradingPair.fromSymbol(symbol);
      expect(pair.base, isNotEmpty, reason: symbol);
      expect(pair.quote, isNotEmpty, reason: symbol);
    }
  });

  test('resolves route symbols to tracked symbols only', () {
    expect(MarketSymbols.resolve('btcusdt'), 'BTCUSDT');
    expect(MarketSymbols.resolve(' ETHUSDT '), 'ETHUSDT');
    expect(MarketSymbols.resolve('NOPEUSDT'), isNull);
    expect(MarketSymbols.resolve(''), isNull);
    expect(MarketSymbols.resolve(null), isNull);
  });
}
