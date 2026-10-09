import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/app/theme/app_colors.dart';

/// Frosted panel: blurs what scrolls beneath it and tints it with [color].
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.color = AppColors.glass,
    this.borderRadius = BorderRadius.zero,
    this.border,
    this.blur = 20,
  });

  final Widget child;
  final Color color;
  final BorderRadius borderRadius;
  final BoxBorder? border;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: borderRadius,
            border: border,
          ),
          child: child,
        ),
      ),
    );
  }
}
