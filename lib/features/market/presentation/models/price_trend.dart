import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/app/theme/app_colors.dart';

enum PriceTrend {
  up(AppColors.positive, Icons.arrow_drop_up),
  down(AppColors.negative, Icons.arrow_drop_down),
  flat(AppColors.neutral, Icons.remove);

  const PriceTrend(this.color, this.icon);

  final Color color;
  final IconData icon;

  static PriceTrend fromChange(double change) {
    if (change > 0) return up;
    if (change < 0) return down;
    return flat;
  }
}
