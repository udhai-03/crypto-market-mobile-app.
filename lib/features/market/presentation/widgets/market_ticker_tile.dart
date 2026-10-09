import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/core/constants/app_radius.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/utils/number_formatters.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/domain/models/trading_pair.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/coin_identity.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/price_trend.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/coin_avatar.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/pair_symbol_text.dart';

/// Flat market row: pair and coin name, last price and volume, 24h change pill.
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
    final onTap = this.onTap;
    final trailing = this.trailing;
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final price = NumberFormatters.price(ticker.lastPrice);
    final volume = AppStrings.amountIn(
      NumberFormatters.compactNumber(ticker.quoteVolume),
      TradingPair.fromSymbol(ticker.symbol).quote,
    );

    return Material(
      type: MaterialType.transparency,
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
                      AppSpacing.medium - 2,
                      trailing == null ? AppSpacing.medium : 0,
                      AppSpacing.medium - 2,
                    ),
                    child: Row(
                      children: [
                        CoinAvatar(symbol: ticker.symbol, size: 38),
                        const SizedBox(width: AppSpacing.medium - 4),
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PairSymbolText(
                                symbol: ticker.symbol,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                CoinIdentity.forSymbol(ticker.symbol).name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: mutedStyle,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  price,
                                  maxLines: 1,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontFeatures: _tabularFigures,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                AppStrings.shortVolume(
                                  NumberFormatters.compactNumber(
                                    ticker.quoteVolume,
                                  ),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: mutedStyle?.copyWith(
                                  fontFeatures: _tabularFigures,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium - 4),
                        ChangePill(percent: ticker.priceChangePercent),
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

/// Clearly visible 24h percentage badge with an up/down arrow and color coding.
class ChangePill extends StatelessWidget {
  const ChangePill({super.key, required this.percent});

  final double percent;

  static const double _minWidth = 82;
  static const double _height = 32;
  static const double _tintAlpha = 0.15;
  static const double _borderAlpha = 0.35;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trend = PriceTrend.fromChange(percent);

    return Container(
      constraints: const BoxConstraints(minWidth: _minWidth),
      height: _height,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: trend == PriceTrend.flat
            ? Colors.white.withValues(alpha: 0.05)
            : trend.color.withValues(alpha: _tintAlpha),
        borderRadius: BorderRadius.circular(AppRadius.badge + 2),
        border: Border.all(
          color: trend == PriceTrend.flat
              ? Colors.white.withValues(alpha: 0.15)
              : trend.color.withValues(alpha: _borderAlpha),
          width: 1.0,
        ),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                trend.icon,
                size: trend == PriceTrend.flat ? 14 : 18,
                color: trend.color,
              ),
              const SizedBox(width: 1),
              Text(
                NumberFormatters.percentChange(percent),
                maxLines: 1,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: trend.color,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
