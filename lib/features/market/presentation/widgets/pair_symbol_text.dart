import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/features/market/domain/models/trading_pair.dart';

/// Pair symbol with an emphasized base asset, e.g. **BTC**USDT.
class PairSymbolText extends StatelessWidget {
  const PairSymbolText({super.key, required this.symbol, this.style});

  final String symbol;
  final TextStyle? style;

  static const double _quoteScale = 0.78;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = (style ?? theme.textTheme.titleMedium)?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final pair = TradingPair.fromSymbol(symbol);

    return Text.rich(
      TextSpan(
        text: pair.base,
        style: baseStyle,
        children: [
          TextSpan(
            text: pair.quote,
            style: baseStyle?.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: (baseStyle.fontSize ?? 16) * _quoteScale,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
