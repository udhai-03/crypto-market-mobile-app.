import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/utils/number_formatters.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/domain/models/trading_pair.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/price_change_badge.dart';

class MarketTickerTile extends StatelessWidget {
  const MarketTickerTile({
    super.key,
    required this.ticker,
    this.onTap,
    this.trailing,
  });

  final MarketTicker ticker;
  final VoidCallback? onTap;

  /// Optional action next to the tile content, e.g. a watchlist star.
  /// Kept outside the tile's tap target and merged semantics.
  final Widget? trailing;

  static const _tabularFigures = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final price = NumberFormatters.price(ticker.lastPrice);
    final volume = AppStrings.amountIn(
      NumberFormatters.compactNumber(ticker.quoteVolume),
      TradingPair.fromSymbol(ticker.symbol).quote,
    );
    final trailing = this.trailing;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              container: true,
              button: onTap != null,
              onTap: onTap,
              label: AppStrings.tickerSemantics(
                symbol: ticker.symbol,
                price: price,
                change: NumberFormatters.percentChange(
                  ticker.priceChangePercent,
                ),
                volume: volume,
              ),
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.medium,
                      AppSpacing.medium,
                      trailing == null ? AppSpacing.medium : AppSpacing.xSmall,
                      AppSpacing.medium,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticker.symbol,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xSmall),
                              Text(
                                '${AppStrings.volumeLabel} $volume',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: mutedStyle?.copyWith(
                                  fontFeatures: _tabularFigures,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                price,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: _tabularFigures,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xSmall),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      AppStrings.change24hLabel,
                                      style: mutedStyle,
                                    ),
                                    const SizedBox(width: AppSpacing.small),
                                    PriceChangeBadge(
                                      percent: ticker.priceChangePercent,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
