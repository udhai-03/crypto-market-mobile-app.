import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/features/market/domain/models/trading_pair.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/coin_identity.dart';

/// Circular coin logo, or the coin's initial on its brand color when no
/// logo is bundled.
class CoinAvatar extends StatelessWidget {
  const CoinAvatar({super.key, required this.symbol, this.size = 36});

  final String symbol;
  final double size;

  static const Duration _fadeIn = Duration(milliseconds: 200);

  /// Keeps dark logos (e.g. XRP, ADA) visible on the dark background.
  static const Color _ring = Color(0x1FFFFFFF);

  @override
  Widget build(BuildContext context) {
    final identity = CoinIdentity.forSymbol(symbol);
    final logo = identity.logoAsset;
    final initial = _Initial(symbol: symbol, identity: identity, size: size);

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        foregroundDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _ring),
        ),
        child: logo == null
            ? initial
            : Image.asset(
                logo,
                width: size,
                height: size,
                filterQuality: FilterQuality.medium,
                errorBuilder: (context, _, _) => initial,
                frameBuilder: (context, child, frame, wasSyncLoaded) {
                  if (wasSyncLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: _fadeIn,
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
              ),
      ),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial({
    required this.symbol,
    required this.identity,
    required this.size,
  });

  final String symbol;
  final CoinIdentity identity;
  final double size;

  static const double _letterScale = 0.44;

  @override
  Widget build(BuildContext context) {
    final base = TradingPair.fromSymbol(symbol).base;

    return DecoratedBox(
      decoration: BoxDecoration(color: identity.color, shape: BoxShape.circle),
      child: Center(
        child: Text(
          base.isEmpty ? '?' : base.characters.first,
          maxLines: 1,
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * _letterScale,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }
}
