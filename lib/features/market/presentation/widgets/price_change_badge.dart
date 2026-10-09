import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/core/constants/app_radius.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/utils/number_formatters.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/price_trend.dart';

/// Signed percentage badge with an up/down arrow and clear color-coded pill.
class PriceChangeBadge extends StatelessWidget {
  const PriceChangeBadge({super.key, required this.percent});

  final double percent;

  static const double _tintAlpha = 0.15;
  static const double _borderAlpha = 0.32;
  static const double _iconSize = 16;

  @override
  Widget build(BuildContext context) {
    final trend = PriceTrend.fromChange(percent);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: trend == PriceTrend.flat
            ? Colors.white.withValues(alpha: 0.06)
            : trend.color.withValues(alpha: _tintAlpha),
        borderRadius: BorderRadius.circular(AppRadius.badge + 2),
        border: Border.all(
          color: trend == PriceTrend.flat
              ? Colors.white.withValues(alpha: 0.15)
              : trend.color.withValues(alpha: _borderAlpha),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(trend.icon, size: _iconSize, color: trend.color),
          const SizedBox(width: 2),
          Text(
            NumberFormatters.percentChange(percent),
            style: theme.textTheme.labelMedium?.copyWith(
              color: trend.color,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
