import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/utils/number_formatters.dart';
import 'package:crypto_market_mobile/core/widgets/skeleton_box.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/models/coin_ticker_state.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/viewmodels/coin_details_view_model.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/price_trend.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_view_model.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/price_change_badge.dart';

/// Current price and 24h change of the selected pair.
class CoinPriceSummary extends ConsumerWidget {
  const CoinPriceSummary({super.key, required this.symbol});

  final String symbol;

  static const double _priceSkeletonHeight = 36;
  static const double _priceSkeletonWidth = 200;
  static const double _changeSkeletonHeight = 20;
  static const double _changeSkeletonWidth = 140;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(coinTickerProvider(symbol))) {
      CoinTickerAvailable(:final ticker) => _PriceDetails(ticker: ticker),
      CoinTickerLoading() => Semantics(
        label: AppStrings.marketsLoading,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(
              height: _priceSkeletonHeight,
              width: _priceSkeletonWidth,
            ),
            SizedBox(height: AppSpacing.small),
            SkeletonBox(
              height: _changeSkeletonHeight,
              width: _changeSkeletonWidth,
            ),
          ],
        ),
      ),
      CoinTickerUnavailable() => _PriceUnavailable(
        onRetry: ref.read(marketViewModelProvider.notifier).refresh,
      ),
    };
  }
}

class _PriceDetails extends StatelessWidget {
  const _PriceDetails({required this.ticker});

  final MarketTicker ticker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trend = PriceTrend.fromChange(ticker.priceChangePercent);

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              NumberFormatters.price(ticker.lastPrice),
              maxLines: 1,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.xSmall,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                NumberFormatters.signedPrice(
                  ticker.priceChange,
                  precisionOf: ticker.lastPrice,
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: trend.color,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              PriceChangeBadge(percent: ticker.priceChangePercent),
              Text(
                AppStrings.change24hLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceUnavailable extends StatelessWidget {
  const _PriceUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(Icons.cloud_off_outlined, color: mutedColor),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: Text(
            AppStrings.priceUnavailable,
            style: theme.textTheme.bodyMedium?.copyWith(color: mutedColor),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
      ],
    );
  }
}
