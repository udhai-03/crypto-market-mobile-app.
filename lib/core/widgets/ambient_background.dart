import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/app/theme/app_colors.dart';

/// Static backdrop: the base color with a few soft, low-contrast color
/// fields so translucent surfaces above it have something to pick up.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.background),
        const _Glow(
          alignment: Alignment(-1.1, -1.0),
          color: AppColors.ambientTeal,
          radius: 1.1,
        ),
        const _Glow(
          alignment: Alignment(1.2, -0.55),
          color: AppColors.ambientIndigo,
          radius: 1.0,
        ),
        const _Glow(
          alignment: Alignment(-0.4, 1.15),
          color: AppColors.ambientBlue,
          radius: 1.2,
        ),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.alignment,
    required this.color,
    required this.radius,
  });

  final Alignment alignment;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: alignment,
            radius: radius,
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
