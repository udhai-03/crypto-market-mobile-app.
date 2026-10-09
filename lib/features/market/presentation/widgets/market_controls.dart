import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/app/theme/app_colors.dart';
import 'package:crypto_market_mobile/core/constants/app_radius.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/widgets/glass_surface.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/market_query.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_query_view_model.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_selectors.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_search_bar.dart';

/// Search field above the market overview.
class MarketControls extends StatelessWidget {
  const MarketControls({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        0,
        AppSpacing.medium,
        AppSpacing.medium,
      ),
      child: MarketSearchBar(),
    );
  }
}

/// Filter and sort bar that stays pinned while the market list scrolls.
class MarketListHeader extends StatelessWidget {
  const MarketListHeader({super.key});

  static const double _topPadding = AppSpacing.medium;
  static const double _labelFontSize = 14;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final trackHeight = math.max(
      MarketFilterBar.minHeight,
      scaler.scale(_labelFontSize) + 24,
    );
    final resultsHeight = math.max(
      kMinInteractiveDimension,
      scaler.scale(_labelFontSize) + 28,
    );

    return SliverPersistentHeader(
      pinned: true,
      delegate: _MarketListHeaderDelegate(
        trackHeight: trackHeight,
        resultsHeight: resultsHeight,
        extent: _topPadding + trackHeight + resultsHeight + 1,
      ),
    );
  }
}

class _MarketListHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _MarketListHeaderDelegate({
    required this.trackHeight,
    required this.resultsHeight,
    required this.extent,
  });

  final double trackHeight;
  final double resultsHeight;
  final double extent;

  static const Duration _dividerFade = Duration(milliseconds: 200);

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isStuck = shrinkOffset > 0 || overlapsContent;

    return GlassSurface(
      color: isStuck ? AppColors.glassStrong : Colors.transparent,
      child: Column(
        children: [
          const SizedBox(height: MarketListHeader._topPadding),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
            child: SizedBox(
              height: trackHeight,
              child: const MarketFilterBar(),
            ),
          ),
          SizedBox(
            height: resultsHeight,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium),
              child: _ResultsHeader(),
            ),
          ),
          AnimatedOpacity(
            opacity: isStuck ? 1 : 0,
            duration: _dividerFade,
            child: const Divider(height: 1, thickness: 1),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_MarketListHeaderDelegate oldDelegate) {
    return oldDelegate.trackHeight != trackHeight ||
        oldDelegate.resultsHeight != resultsHeight ||
        oldDelegate.extent != extent;
  }
}

/// Segmented All / Gainers / Losers control with a sliding thumb and color-coded counts.
class MarketFilterBar extends ConsumerWidget {
  const MarketFilterBar({super.key});

  static const double minHeight = 44;
  static const double _inset = 3;
  static const Duration _slide = Duration(milliseconds: 280);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(
      marketQueryProvider.select((query) => query.filter),
    );
    final summary = ref.watch(marketSummaryProvider);
    final theme = Theme.of(context);
    final options = MarketFilter.values;
    final selectedIndex = options.indexOf(filter);
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _slide;

    final counts = {
      MarketFilter.all: summary.trackedCount,
      MarketFilter.gainers: summary.gainersCount,
      MarketFilter.losers: summary.losersCount,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: BorderRadius.circular(AppRadius.badge + 4),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_inset),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: duration,
              curve: Curves.easeOutCubic,
              alignment: Alignment(
                -1 + 2 * selectedIndex / (options.length - 1),
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / options.length,
                heightFactor: 1,
                child: AnimatedContainer(
                  duration: duration,
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: switch (filter) {
                      MarketFilter.all => const Color(0xFF1E2837),
                      MarketFilter.gainers => const Color(0xFF0F2B20),
                      MarketFilter.losers => const Color(0xFF2C131B),
                    },
                    borderRadius: BorderRadius.circular(AppRadius.badge + 1),
                    border: Border.all(
                      color: switch (filter) {
                        MarketFilter.all => const Color(0x33FFFFFF),
                        MarketFilter.gainers => AppColors.positive.withValues(
                          alpha: 0.45,
                        ),
                        MarketFilter.losers => AppColors.negative.withValues(
                          alpha: 0.45,
                        ),
                      },
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: switch (filter) {
                          MarketFilter.all => const Color(0x40000000),
                          MarketFilter.gainers => AppColors.positive.withValues(
                            alpha: 0.18,
                          ),
                          MarketFilter.losers => AppColors.negative.withValues(
                            alpha: 0.18,
                          ),
                        },
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final option in options)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: option == filter,
                      inMutuallyExclusiveGroup: true,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.badge),
                        onTap: () => ref
                            .read(marketQueryProvider.notifier)
                            .selectFilter(option),
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    switch (option) {
                                      MarketFilter.all =>
                                        Icons.grid_view_rounded,
                                      MarketFilter.gainers =>
                                        Icons.trending_up_rounded,
                                      MarketFilter.losers =>
                                        Icons.trending_down_rounded,
                                    },
                                    size: 13,
                                    color: option == filter
                                        ? (option == MarketFilter.all
                                              ? Colors.white
                                              : (option == MarketFilter.gainers
                                                    ? AppColors.positive
                                                    : AppColors.negative))
                                        : theme.colorScheme.onSurfaceVariant
                                              .withValues(alpha: 0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  AnimatedDefaultTextStyle(
                                    duration: duration,
                                    style: theme.textTheme.labelMedium!
                                        .copyWith(
                                          fontWeight: option == filter
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: option == filter
                                              ? (option == MarketFilter.all
                                                    ? Colors.white
                                                    : (option ==
                                                              MarketFilter
                                                                  .gainers
                                                          ? AppColors.positive
                                                          : AppColors.negative))
                                              : theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                        ),
                                    child: Text(option.label, maxLines: 1),
                                  ),
                                  if (counts[option] case final count?
                                      when count > 0) ...[
                                    const SizedBox(width: 5),
                                    _TabCountBadge(
                                      count: count,
                                      isSelected: option == filter,
                                      filter: option,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TabCountBadge extends StatelessWidget {
  const _TabCountBadge({
    required this.count,
    required this.isSelected,
    required this.filter,
  });

  final int count;
  final bool isSelected;
  final MarketFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = switch (filter) {
      MarketFilter.all => Colors.white,
      MarketFilter.gainers => AppColors.positive,
      MarketFilter.losers => AppColors.negative,
    };

    final bg = isSelected
        ? (filter == MarketFilter.all
              ? Colors.white.withValues(alpha: 0.14)
              : accentColor.withValues(alpha: 0.22))
        : (filter == MarketFilter.all
              ? Colors.white.withValues(alpha: 0.06)
              : accentColor.withValues(alpha: 0.10));

    final fg = isSelected
        ? accentColor
        : (filter == MarketFilter.all
              ? theme.colorScheme.onSurfaceVariant
              : accentColor.withValues(alpha: 0.8));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          height: 1.2,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          color: fg,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _ResultsHeader extends ConsumerWidget {
  const _ResultsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultCount = ref.watch(
      visibleMarketTickersProvider.select((tickers) => tickers.length),
    );
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            AppStrings.pairCount(resultCount),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Flexible(
          child: Align(
            alignment: Alignment.centerRight,
            child: MarketSortMenu(),
          ),
        ),
      ],
    );
  }
}

class MarketSortMenu extends ConsumerWidget {
  const MarketSortMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(marketQueryProvider.select((query) => query.sort));
    final theme = Theme.of(context);
    final color = sort == MarketSort.defaultOrder
        ? theme.colorScheme.onSurfaceVariant
        : theme.colorScheme.primary;

    return PopupMenuButton<MarketSort>(
      tooltip: AppStrings.sortTooltip,
      initialValue: sort,
      onSelected: ref.read(marketQueryProvider.notifier).selectSort,
      itemBuilder: (context) => [
        for (final option in MarketSort.values)
          CheckedPopupMenuItem(
            value: option,
            checked: option == sort,
            child: Text(option.label),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_vert_rounded, size: 18, color: color),
            const SizedBox(width: AppSpacing.xSmall),
            Flexible(
              child: Text(
                sort.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
