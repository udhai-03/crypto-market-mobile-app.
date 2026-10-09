import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/app/theme/app_colors.dart';
import 'package:crypto_market_mobile/core/constants/app_radius.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/features/market/domain/models/live_connection_status.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_selectors.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_view_model.dart';

/// Small pill showing whether displayed prices are being updated live.
/// Hidden until market data is available.
class LiveStatusIndicator extends ConsumerWidget {
  const LiveStatusIndicator({super.key});

  static const double _backgroundAlpha = 0.14;
  static const double _dotSize = 6;
  static const Duration _transition = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMarketData = ref.watch(
      marketViewModelProvider.select((state) => state.hasValue),
    );
    if (!hasMarketData) return const SizedBox.shrink();

    final status = ref.watch(marketConnectionStatusProvider);
    final (label, color) = switch (status) {
      LiveConnectionStatus.connected => (
        AppStrings.liveStatusLive,
        AppColors.positive,
      ),
      LiveConnectionStatus.connecting => (
        AppStrings.liveStatusConnecting,
        AppColors.warning,
      ),
      LiveConnectionStatus.reconnecting => (
        AppStrings.liveStatusReconnecting,
        AppColors.warning,
      ),
      LiveConnectionStatus.disconnected => (
        AppStrings.liveStatusOffline,
        AppColors.negative,
      ),
    };

    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _transition;

    return Semantics(
      label: AppStrings.liveStatusSemantics(label),
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: duration,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.small + 2,
            vertical: AppSpacing.xSmall,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: _backgroundAlpha),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: duration,
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.small),
              AnimatedDefaultTextStyle(
                duration: duration,
                style: Theme.of(context).textTheme.labelMedium!
                    .copyWith(color: color, fontWeight: FontWeight.w600),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
