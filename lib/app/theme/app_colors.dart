import 'package:flutter/material.dart';

/// Central palette for the dark crypto dashboard.
abstract final class AppColors {
  static const Color background = Color(0xFF0B0F14);
  static const Color surface = Color(0xFF121821);
  static const Color surfaceHigh = Color(0xFF1C2633);

  static const Color primary = Color(0xFF5EEAD4);
  static const Color onPrimary = Color(0xFF042F2E);

  static const Color secondary = Color(0xFF7DD3FC);
  static const Color onSecondary = Color(0xFF04202C);

  static const Color textPrimary = Color(0xFFE8EEF4);
  static const Color textSecondary = Color(0xFF93A1B3);

  static const Color outline = Color(0xFF2A3544);

  /// Low-emphasis icons such as an unselected watchlist star.
  static const Color outlineStrong = Color(0xFF55647A);

  /// Raised selection inside segmented tracks.
  static const Color thumb = Color(0x1FFFFFFF);

  static const Color positive = Color(0xFF3DDC97);
  static const Color negative = Color(0xFFFF5C7A);
  static const Color neutral = textSecondary;
  static const Color onNegative = Color(0xFF2A0610);
  static const Color warning = Color(0xFFFBBF24);
  static const Color favorite = Color(0xFFFBBF24);

  static const Color navIndicator = Color(0x2E5EEAD4);

  /// Ambient background washes; kept faint so content stays dominant.
  static const Color ambientTeal = Color(0x4014B8A6);
  static const Color ambientIndigo = Color(0x3D6366F1);
  static const Color ambientBlue = Color(0x2B0EA5E9);

  /// Frosted surfaces over the ambient background.
  static const Color glass = Color(0xB3121821);
  static const Color glassStrong = Color(0xCC0B0F14);

  /// Medium-transparency glass for the floating navigation bar (~70% opacity).
  static const Color glassBar = Color(0xB3101622);
  static const Color glassHighlight = Color(0x29FFFFFF);
  static const Color glassBorder = Color(0x1FFFFFFF);
  static const Color glassFill = Color(0x0FFFFFFF);
  static const Color hairline = Color(0x12FFFFFF);
}
