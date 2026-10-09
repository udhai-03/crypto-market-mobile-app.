import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/market_query.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_query_view_model.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_selectors.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_search_bar.dart';

/// Search, filter, and sort controls above the market list.
class MarketControls extends StatelessWidget {
  const MarketControls({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.screen,
        AppSpacing.medium,
        AppSpacing.xSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MarketSearchBar(),
          SizedBox(height: AppSpacing.medium),
          MarketFilterBar(),
          SizedBox(height: AppSpacing.small),
          _ResultsHeader(),
        ],
      ),
    );
  }
}

class MarketFilterBar extends ConsumerWidget {
  const MarketFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(
      marketQueryProvider.select((query) => query.filter),
    );

    return SegmentedButton<MarketFilter>(
      expandedInsets: EdgeInsets.zero,
      showSelectedIcon: false,
      segments: [
        for (final option in MarketFilter.values)
          ButtonSegment(value: option, label: Text(option.label)),
      ],
      selected: {filter},
      onSelectionChanged: (selection) =>
          ref.read(marketQueryProvider.notifier).selectFilter(selection.single),
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
        const Flexible(child: MarketSortMenu()),
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
            Icon(Icons.swap_vert, color: theme.colorScheme.primary),
            const SizedBox(width: AppSpacing.xSmall),
            Flexible(
              child: Text(
                sort.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
