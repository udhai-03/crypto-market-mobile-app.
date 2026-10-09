import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/utils/number_formatters.dart';
import 'package:crypto_market_mobile/features/market/domain/models/trading_pair.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/price_trend.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_selectors.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_stat_card.dart';

class MarketSummarySection extends ConsumerWidget {
  const MarketSummarySection({super.key});

  static const double _wideLayoutMinWidth = 600;
  static const int _compactColumns = 2;
  static const int _wideColumns = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(marketSummaryProvider);
    final theme = Theme.of(context);
    final averageTrend = PriceTrend.fromChange(summary.averageChangePercent);
    final topVolume = summary.topVolumeTicker;

    final stats = [
      MarketStatCard(
        label: AppStrings.statTrackedPairs,
        value: '${summary.trackedCount}',
      ),
      MarketStatCard(
        label: AppStrings.statAverageChange,
        value: NumberFormatters.percentChange(summary.averageChangePercent),
        icon: averageTrend.icon,
        valueColor: averageTrend.color,
      ),
      MarketStatCard(
        label: AppStrings.statGainers,
        value: '${summary.gainersCount}',
        icon: PriceTrend.up.icon,
        valueColor: PriceTrend.up.color,
      ),
      MarketStatCard(
        label: AppStrings.statLosers,
        value: '${summary.losersCount}',
        icon: PriceTrend.down.icon,
        valueColor: PriceTrend.down.color,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.summaryTitle, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.xSmall),
          Text(
            AppStrings.summaryCaption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= _wideLayoutMinWidth
                  ? _wideColumns
                  : _compactColumns;
              final cardWidth =
                  (constraints.maxWidth - AppSpacing.small * (columns - 1)) /
                  columns;

              return Wrap(
                spacing: AppSpacing.small,
                runSpacing: AppSpacing.small,
                children: [
                  for (final stat in stats)
                    SizedBox(width: cardWidth, child: stat),
                  if (topVolume != null)
                    SizedBox(
                      width: constraints.maxWidth,
                      child: MarketStatCard(
                        label: AppStrings.statTopVolume,
                        value: topVolume.symbol,
                        caption: AppStrings.amountIn(
                          NumberFormatters.compactNumber(topVolume.quoteVolume),
                          TradingPair.fromSymbol(topVolume.symbol).quote,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
