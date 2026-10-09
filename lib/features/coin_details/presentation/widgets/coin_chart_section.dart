import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/core/widgets/skeleton_box.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/viewmodels/coin_details_view_model.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/widgets/chart_timeframe_selector.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/widgets/price_history_chart.dart';

/// Timeframe selector plus the chart and its loading, error, and empty
/// states. Failures here never affect the rest of the Coin Details screen.
class CoinChartSection extends ConsumerWidget {
  const CoinChartSection({super.key, required this.symbol});

  final String symbol;

  static const double _readoutHeight = 72;
  static const double _areaHeight =
      PriceHistoryChart.chartHeight + _readoutHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeframe = ref.watch(coinDetailsViewModelProvider(symbol));
    final chart = ref.watch(coinChartProvider(symbol));
    final viewModel = ref.read(coinDetailsViewModelProvider(symbol).notifier);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.chartTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          AppStrings.chartHistoricalNote,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        ChartTimeframeSelector(
          selected: timeframe,
          onSelected: viewModel.selectTimeframe,
        ),
        const SizedBox(height: AppSpacing.medium),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _areaHeight),
          child: switch (chart) {
            AsyncValue(isLoading: true) => const _ChartLoading(),
            AsyncValue(:final value?) when value.hasEnoughData =>
              PriceHistoryChart(data: value),
            AsyncValue(hasValue: true) => const _ChartMessage(
              icon: Icons.show_chart,
              title: AppStrings.chartEmptyTitle,
              message: AppStrings.chartEmptyMessage,
            ),
            AsyncValue(:final error?) => _ChartMessage(
              icon: Icons.cloud_off_outlined,
              title: AppStrings.chartErrorTitle,
              message: error is AppException
                  ? error.message
                  : AppStrings.unexpectedError,
              onRetry: viewModel.retryChart,
            ),
            _ => const _ChartLoading(),
          },
        ),
      ],
    );
  }
}

class _ChartLoading extends StatelessWidget {
  const _ChartLoading();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.chartLoading,
      child: const SkeletonBox(height: CoinChartSection._areaHeight),
    );
  }
}

class _ChartMessage extends StatelessWidget {
  const _ChartMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  static const double _iconSize = 40;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final onRetry = this.onRetry;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: _iconSize, color: mutedColor),
          const SizedBox(height: AppSpacing.small),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.medium),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text(AppStrings.retry),
            ),
          ],
        ],
      ),
    );
  }
}
