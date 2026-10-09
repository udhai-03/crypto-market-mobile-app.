import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/core/constants/app_radius.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, required this.height, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    );
  }
}
