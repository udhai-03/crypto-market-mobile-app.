import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crypto_market_mobile/app/theme/app_colors.dart';
import 'package:crypto_market_mobile/core/constants/app_radius.dart';
import 'package:crypto_market_mobile/core/constants/app_routes.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/utils/number_formatters.dart';
import 'package:crypto_market_mobile/core/widgets/animated_number_text.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/domain/models/trading_pair.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/market_summary.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/price_trend.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_selectors.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/coin_avatar.dart';

/// "Market pulse" card: average move, market breadth sentiment gauge, and standout pairs.
class MarketSummarySection extends ConsumerWidget {
  const MarketSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(marketSummaryProvider);
    final theme = Theme.of(context);
    final averageTrend = PriceTrend.fromChange(summary.averageChangePercent);
    final topVolume = summary.topVolumeTicker;

    final totalBreadth = summary.gainersCount + summary.losersCount;
    final bullPct = totalBreadth > 0
        ? ((summary.gainersCount / totalBreadth) * 100).round()
        : 50;
    final bearPct = totalBreadth > 0
        ? ((summary.losersCount / totalBreadth) * 100).round()
        : 50;
    final isBullish = summary.gainersCount > summary.losersCount;
    final isBearish = summary.losersCount > summary.gainersCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(AppRadius.panel + 4),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium + 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.summaryTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppStrings.summaryCaption,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _SentimentBadge(
                    isBullish: isBullish,
                    isBearish: isBearish,
                    bullPct: bullPct,
                    bearPct: bearPct,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium + 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: MarketMetric(
                      label: AppStrings.statAverageChange,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedNumberText(
                          value: summary.averageChangePercent,
                          format: NumberFormatters.percentChange,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                            color: averageTrend.color,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  MarketMetric(
                    label: AppStrings.statTrackedPairs,
                    alignEnd: true,
                    child: AnimatedNumberText(
                      value: summary.trackedCount.toDouble(),
                      format: _wholeNumber,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium + 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.arrow_drop_up_rounded,
                        size: 16,
                        color: PriceTrend.up.color,
                      ),
                      Text(
                        '$bullPct% Bulls',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: PriceTrend.up.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$bearPct% Bears',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: PriceTrend.down.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 16,
                        color: PriceTrend.down.color,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xSmall),
              MarketBreadthBar(summary: summary),
              const SizedBox(height: AppSpacing.small + 4),
              Row(
                children: [
                  Expanded(
                    child: _BreadthCount(
                      label: AppStrings.statGainers,
                      count: summary.gainersCount,
                      color: PriceTrend.up.color,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: _BreadthCount(
                      label: AppStrings.statLosers,
                      count: summary.losersCount,
                      color: PriceTrend.down.color,
                      icon: Icons.trending_down_rounded,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium + 4),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _HighlightTile(
                        label: AppStrings.statTopGainer,
                        ticker: summary.topGainer,
                        value: _change,
                        valueColor: PriceTrend.up.color,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: _HighlightTile(
                        label: AppStrings.statTopLoser,
                        ticker: summary.topLoser,
                        value: _change,
                        valueColor: PriceTrend.down.color,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: _HighlightTile(
                        label: AppStrings.statTopVolume,
                        ticker: topVolume,
                        value: _quoteVolume,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _wholeNumber(double value) => '${value.round()}';

  static String _change(MarketTicker ticker) =>
      NumberFormatters.percentChange(ticker.priceChangePercent);

  static String _quoteVolume(MarketTicker ticker) => AppStrings.amountIn(
    NumberFormatters.compactNumber(ticker.quoteVolume),
    TradingPair.fromSymbol(ticker.symbol).quote,
  );
}

class _SentimentBadge extends StatelessWidget {
  const _SentimentBadge({
    required this.isBullish,
    required this.isBearish,
    required this.bullPct,
    required this.bearPct,
  });

  final bool isBullish;
  final bool isBearish;
  final int bullPct;
  final int bearPct;

  @override
  Widget build(BuildContext context) {
    final color = isBullish
        ? AppColors.positive
        : (isBearish ? AppColors.negative : AppColors.textSecondary);
    final label = isBullish
        ? 'Bullish ($bullPct%)'
        : (isBearish ? 'Bearish ($bearPct%)' : 'Neutral (50%)');
    final icon = isBullish
        ? Icons.trending_up_rounded
        : (isBearish
              ? Icons.trending_down_rounded
              : Icons.horizontal_rule_rounded);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small muted label above a value, read as one semantic node.
class MarketMetric extends StatelessWidget {
  const MarketMetric({
    super.key,
    required this.label,
    required this.child,
    this.alignEnd = false,
  });

  final String label;
  final Widget child;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xSmall),
          child,
        ],
      ),
    );
  }
}

/// Split bar of gainers and losers that grows in on first load.
class MarketBreadthBar extends StatelessWidget {
  const MarketBreadthBar({super.key, required this.summary});

  final MarketSummary summary;

  static const double _height = 10;
  static const double _gap = 3;
  static const Duration _duration = Duration(milliseconds: 800);

  @override
  Widget build(BuildContext context) {
    final total = summary.trackedCount;
    final gainers = total == 0 ? 0.0 : summary.gainersCount / total;
    final losers = total == 0 ? 0.0 : summary.losersCount / total;

    return ExcludeSemantics(
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(begin: Offset.zero, end: Offset(gainers, losers)),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : _duration,
        curve: Curves.easeOutCubic,
        builder: (context, split, _) => Container(
          height: _height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: PriceTrend.up.color.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(-2, 0),
              ),
              BoxShadow(
                color: PriceTrend.down.color.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(2, 0),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                children: [
                  Positioned.fill(child: _Segment(color: AppColors.glassFill)),
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: (width * split.dx - _gap / 2).clamp(0, width),
                    child: _GradientSegment(
                      colors: [const Color(0xFF10B981), PriceTrend.up.color],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: (width * split.dy - _gap / 2).clamp(0, width),
                    child: _GradientSegment(
                      colors: [PriceTrend.down.color, const Color(0xFFEF4444)],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GradientSegment extends StatelessWidget {
  const _GradientSegment({required this.colors});

  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

class _BreadthCount extends StatelessWidget {
  const _BreadthCount({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    this.alignEnd = false,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isGainer = color == PriceTrend.up.color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium - 4,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: isGainer
            ? AppColors.positive.withValues(alpha: 0.08)
            : AppColors.negative.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.card - 2),
        border: Border.all(
          color: isGainer
              ? AppColors.positive.withValues(alpha: 0.22)
              : AppColors.negative.withValues(alpha: 0.22),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: MarketMetric(
              label: label,
              alignEnd: alignEnd,
              child: AnimatedNumberText(
                value: count.toDouble(),
                format: MarketSummarySection._wholeNumber,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact tappable tile naming one standout pair.
class _HighlightTile extends StatelessWidget {
  const _HighlightTile({
    required this.label,
    required this.ticker,
    required this.value,
    this.valueColor,
  });

  final String label;
  final MarketTicker? ticker;
  final String Function(MarketTicker ticker) value;
  final Color? valueColor;

  static const double _avatarSize = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ticker = this.ticker;
    final mutedColor = theme.colorScheme.onSurfaceVariant;

    return Material(
      color: AppColors.glassFill,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: ticker == null
            ? null
            : () => context.push(AppRoutes.coinDetailsLocation(ticker.symbol)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: valueColor != null
                  ? valueColor!.withValues(alpha: 0.20)
                  : const Color(0x18FFFFFF),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.medium - 4),
          child: MarketMetric(
            label: label,
            child: ticker == null
                ? Text(
                    '—',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: mutedColor,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.xSmall),
                      Row(
                        children: [
                          CoinAvatar(symbol: ticker.symbol, size: _avatarSize),
                          const SizedBox(width: AppSpacing.small - 2),
                          Expanded(
                            child: Text(
                              TradingPair.fromSymbol(ticker.symbol).base,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xSmall + 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value(ticker),
                          maxLines: 1,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: valueColor ?? mutedColor,
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
