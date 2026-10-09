import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/core/constants/app_radius.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/utils/number_formatters.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/price_trend.dart';

/// Signed percentage with an arrow, so the trend is not conveyed by color only.
class PriceChangeBadge extends StatelessWidget {
  const PriceChangeBadge({super.key, required this.percent});

  final double percent;

  static const double _backgroundAlpha = 0.14;
  static const double _iconSize = 18;

  @override
  Widget build(BuildContext context) {
    final trend = PriceTrend.fromChange(percent);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: trend.color.withValues(alpha: _backgroundAlpha),
        borderRadius: BorderRadius.circular(AppRadius.badge),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xSmall,
          AppSpacing.xSmall / 2,
          AppSpacing.small,
          AppSpacing.xSmall / 2,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(trend.icon, size: _iconSize, color: trend.color),
            Text(
              NumberFormatters.percentChange(percent),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: trend.color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
