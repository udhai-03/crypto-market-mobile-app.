import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/app/theme/app_colors.dart';

enum PriceTrend {
  up(
    AppColors.positive,
    Icons.arrow_drop_up_rounded,
    Icons.trending_up_rounded,
  ),
  down(
    AppColors.negative,
    Icons.arrow_drop_down_rounded,
    Icons.trending_down_rounded,
  ),
  flat(AppColors.neutral, Icons.remove_rounded, Icons.trending_flat_rounded);

  const PriceTrend(this.color, this.icon, this.trendIcon);

  final Color color;

  /// Compact arrow for inline badges.
  final IconData icon;

  /// Chart-style symbol for headline statistics.
  final IconData trendIcon;

  static PriceTrend fromChange(double change) {
    if (change > 0) return up;
    if (change < 0) return down;
    return flat;
  }
}
