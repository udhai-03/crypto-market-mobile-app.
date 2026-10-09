import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/features/market/domain/models/trading_pair.dart';

/// Visual identity of a base asset: display name, logo, and brand color.
class CoinIdentity {
  const CoinIdentity({required this.name, required this.color, this.logoAsset});

  factory CoinIdentity.forSymbol(String symbol) {
    final base = TradingPair.fromSymbol(symbol).base;
    return _known[base] ??
        CoinIdentity(
          name: base,
          color:
              _fallbackPalette[base.hashCode.abs() % _fallbackPalette.length],
        );
  }

  final String name;
  final Color color;

  /// Bundled logo; coins without one show their initial instead.
  final String? logoAsset;

  static const _known = <String, CoinIdentity>{
    'BTC': CoinIdentity(
      name: 'Bitcoin',
      color: Color(0xFFF7931A),
      logoAsset: 'assets/coins/btc.png',
    ),
    'ETH': CoinIdentity(
      name: 'Ethereum',
      color: Color(0xFF7B8CEF),
      logoAsset: 'assets/coins/eth.png',
    ),
    'BNB': CoinIdentity(
      name: 'BNB',
      color: Color(0xFFF3BA2F),
      logoAsset: 'assets/coins/bnb.png',
    ),
    'SOL': CoinIdentity(
      name: 'Solana',
      color: Color(0xFF9945FF),
      logoAsset: 'assets/coins/sol.png',
    ),
    'XRP': CoinIdentity(
      name: 'XRP',
      color: Color(0xFF00AAE4),
      logoAsset: 'assets/coins/xrp.png',
    ),
    'DOGE': CoinIdentity(
      name: 'Dogecoin',
      color: Color(0xFFC2A633),
      logoAsset: 'assets/coins/doge.png',
    ),
    'ADA': CoinIdentity(
      name: 'Cardano',
      color: Color(0xFF3468D1),
      logoAsset: 'assets/coins/ada.png',
    ),
    'TRX': CoinIdentity(
      name: 'TRON',
      color: Color(0xFFFF3B3F),
      logoAsset: 'assets/coins/trx.png',
    ),
    'AVAX': CoinIdentity(
      name: 'Avalanche',
      color: Color(0xFFE84142),
      logoAsset: 'assets/coins/avax.png',
    ),
    'LINK': CoinIdentity(
      name: 'Chainlink',
      color: Color(0xFF3D6FE8),
      logoAsset: 'assets/coins/link.png',
    ),
    'DOT': CoinIdentity(
      name: 'Polkadot',
      color: Color(0xFFE6007A),
      logoAsset: 'assets/coins/dot.png',
    ),
    'LTC': CoinIdentity(
      name: 'Litecoin',
      color: Color(0xFF5A8BD6),
      logoAsset: 'assets/coins/ltc.png',
    ),
  };

  static const _fallbackPalette = [
    Color(0xFF5EEAD4),
    Color(0xFF7DD3FC),
    Color(0xFFA78BFA),
    Color(0xFFF472B6),
    Color(0xFFFBBF24),
  ];
}
