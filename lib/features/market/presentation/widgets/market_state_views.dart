import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/widgets/shimmer.dart';
import 'package:crypto_market_mobile/core/widgets/skeleton_box.dart';
import 'package:crypto_market_mobile/core/widgets/status_message_view.dart';

/// Placeholder layout shown while market data loads for the first time.
class MarketLoadingSliver extends StatelessWidget {
  const MarketLoadingSliver({super.key});

  static const double _panelHeight = 196;
  static const double _filterHeight = 40;
  static const int _placeholderRows = 6;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      sliver: SliverToBoxAdapter(
        child: Semantics(
          label: AppStrings.marketsLoading,
          child: ExcludeSemantics(
            child: Shimmer(
              child: Column(
                children: [
                  const SkeletonBox(height: kMinInteractiveDimension),
                  const SizedBox(height: AppSpacing.medium),
                  const SkeletonBox(height: _panelHeight),
                  const SizedBox(height: AppSpacing.medium),
                  const SkeletonBox(height: _filterHeight),
                  const SizedBox(height: AppSpacing.small),
                  for (var i = 0; i < _placeholderRows; i++)
                    const _RowPlaceholder(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowPlaceholder extends StatelessWidget {
  const _RowPlaceholder();

  static const double _avatarSize = 36;
  static const double _lineHeight = 12;
  static const double _pillWidth = 74;
  static const double _pillHeight = 30;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium - 2),
      child: Row(
        children: [
          Container(
            width: _avatarSize,
            height: _avatarSize,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.medium - 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: _lineHeight, width: 88),
                SizedBox(height: AppSpacing.small),
                SkeletonBox(height: _lineHeight, width: 120),
              ],
            ),
          ),
          const SkeletonBox(height: _lineHeight, width: 64),
          const SizedBox(width: AppSpacing.medium - 4),
          const SkeletonBox(height: _pillHeight, width: _pillWidth),
        ],
      ),
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
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        child: StatusMessageView(
          icon: icon,
          title: title,
          message: message,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
  }
}
