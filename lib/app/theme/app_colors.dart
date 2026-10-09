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

  static const Color positive = Color(0xFF3DDC97);
  static const Color negative = Color(0xFFFF5C7A);
  static const Color neutral = textSecondary;
  static const Color onNegative = Color(0xFF2A0610);
  static const Color warning = Color(0xFFFBBF24);
  static const Color favorite = Color(0xFFFBBF24);

  static const Color navIndicator = Color(0x2E5EEAD4);
}
