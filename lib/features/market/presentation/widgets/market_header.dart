import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/live_status_indicator.dart';

/// Screen title with the live connection status, shared by market screens.
class MarketHeader extends StatelessWidget {
  const MarketHeader({
    super.key,
    this.title = AppStrings.marketsTitle,
    this.subtitle = AppStrings.marketsSubtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.screen,
        AppSpacing.medium,
        AppSpacing.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.xSmall,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              const LiveStatusIndicator(),
            ],
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
