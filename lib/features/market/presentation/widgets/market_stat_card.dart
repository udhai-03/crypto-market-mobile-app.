import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/core/constants/app_spacing.dart';

class MarketStatCard extends StatelessWidget {
  const MarketStatCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;
  final Color? valueColor;

  static const double _iconSize = 22;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final icon = this.icon;
    final caption = this.caption;

    return MergeSemantics(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(color: mutedColor),
              ),
              const SizedBox(height: AppSpacing.small),
              Row(
                children: [
                  if (icon != null)
                    Icon(icon, size: _iconSize, color: valueColor),
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: valueColor,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      caption,
                      maxLines: 1,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: mutedColor,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
