import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/app/theme/app_colors.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/utils/number_formatters.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/models/coin_ticker_state.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/viewmodels/coin_details_view_model.dart';
import 'package:crypto_market_mobile/features/market/domain/models/trading_pair.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/coin_identity.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/price_trend.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_stat_card.dart';

/// 24h statistics of the selected pair; hidden until its ticker is known.
class CoinMarketStats extends ConsumerWidget {
  const CoinMarketStats({super.key, required this.symbol});

  final String symbol;

  static const double _wideLayoutMinWidth = 600;
  static const int _compactColumns = 2;
  static const int _wideColumns = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(coinTickerProvider(symbol));
    if (state is! CoinTickerAvailable) return const SizedBox.shrink();

    final ticker = state.ticker;
    final pair = TradingPair.fromSymbol(ticker.symbol);
    final trend = PriceTrend.fromChange(ticker.priceChange);

    final stats = [
      MarketStatCard(
        label: AppStrings.statHigh24h,
        value: NumberFormatters.price(ticker.highPrice),
        icon: Icons.north_east_rounded,
        accentColor: PriceTrend.up.color,
      ),
      MarketStatCard(
        label: AppStrings.statLow24h,
        value: NumberFormatters.price(ticker.lowPrice),
        icon: Icons.south_east_rounded,
        accentColor: PriceTrend.down.color,
      ),
      MarketStatCard(
        label: AppStrings.statChange24h,
        value: NumberFormatters.signedPrice(
          ticker.priceChange,
          precisionOf: ticker.lastPrice,
        ),
        icon: trend.trendIcon,
        valueColor: trend.color,
      ),
      MarketStatCard(
        label: AppStrings.volumeIn(pair.base),
        value: NumberFormatters.compactNumber(ticker.volume),
        icon: Icons.toll_outlined,
        accentColor: CoinIdentity.forSymbol(ticker.symbol).color,
      ),
      MarketStatCard(
        label: AppStrings.volumeIn(pair.quote),
        value: NumberFormatters.compactNumber(ticker.quoteVolume),
        icon: Icons.payments_outlined,
        accentColor: AppColors.secondary,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.statsTitle,
          style: Theme.of(context).textTheme.titleSmall,
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
              ],
            );
          },
        ),
      ],
    );
  }
}
