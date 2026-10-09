import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/core/constants/app_radius.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';

class MarketStatCard extends StatelessWidget {
  const MarketStatCard({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.accentColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final String? caption;
  final IconData? icon;

  /// Tint of the icon chip; defaults to [valueColor] or the primary color.
  final Color? accentColor;
  final Color? valueColor;

  static const double _iconSize = 18;
  static const double _chipSize = 32;
  static const double _chipAlpha = 0.16;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final accent = accentColor ?? valueColor ?? theme.colorScheme.primary;
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: mutedColor,
                      ),
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: AppSpacing.small),
                    Container(
                      width: _chipSize,
                      height: _chipSize,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: _chipAlpha),
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                      ),
                      child: Icon(icon, size: _iconSize, color: accent),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.small),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
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
