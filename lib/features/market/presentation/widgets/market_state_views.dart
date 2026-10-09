import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/widgets/skeleton_box.dart';
import 'package:crypto_market_mobile/core/widgets/status_message_view.dart';

/// Placeholder layout shown while market data loads for the first time.
class MarketLoadingSliver extends StatelessWidget {
  const MarketLoadingSliver({super.key});

  static const double _statHeight = 76;
  static const double _tileHeight = 72;
  static const int _placeholderTiles = 6;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      sliver: SliverToBoxAdapter(
        child: Semantics(
          label: AppStrings.marketsLoading,
          child: ExcludeSemantics(
            child: Column(
              children: [
                const _StatPlaceholderRow(height: _statHeight),
                const SizedBox(height: AppSpacing.small),
                const _StatPlaceholderRow(height: _statHeight),
                const SizedBox(height: AppSpacing.screen),
                const SkeletonBox(height: kMinInteractiveDimension),
                const SizedBox(height: AppSpacing.medium),
                for (var i = 0; i < _placeholderTiles; i++) ...const [
                  SkeletonBox(height: _tileHeight),
                  SizedBox(height: AppSpacing.small),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPlaceholderRow extends StatelessWidget {
  const _StatPlaceholderRow({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: SkeletonBox(height: height)),
        const SizedBox(width: AppSpacing.small),
        Expanded(child: SkeletonBox(height: height)),
      ],
    );
  }
}

/// Fills the remaining scroll space with a centered status message.
class MarketMessageSliver extends StatelessWidget {
  const MarketMessageSliver({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: StatusMessageView(
        icon: icon,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      ),
    );
  }
}
