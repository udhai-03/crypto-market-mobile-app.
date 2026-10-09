import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crypto_market_mobile/core/constants/app_routes.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_query_view_model.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_selectors.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_state_views.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_ticker_tile.dart';
import 'package:crypto_market_mobile/features/watchlist/presentation/widgets/watchlist_toggle_button.dart';

/// Sliver showing the searched, filtered, and sorted market tickers.
class MarketTickerList extends ConsumerWidget {
  const MarketTickerList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickers = ref.watch(visibleMarketTickersProvider);

    if (tickers.isEmpty) {
      return MarketMessageSliver(
        icon: Icons.search_off,
        title: AppStrings.noResultsTitle,
        message: AppStrings.noResultsMessage,
        actionLabel: AppStrings.clearSearchAndFilter,
        onAction: ref.read(marketQueryProvider.notifier).clearSearchAndFilter,
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        AppSpacing.small,
        AppSpacing.medium,
        AppSpacing.screen,
      ),
      sliver: SliverList.separated(
        itemCount: tickers.length,
        itemBuilder: (context, index) {
          final ticker = tickers[index];
          return MarketTickerTile(
            key: ValueKey(ticker.symbol),
            ticker: ticker,
            onTap: () =>
                context.push(AppRoutes.coinDetailsLocation(ticker.symbol)),
            trailing: WatchlistToggleButton(symbol: ticker.symbol),
          );
        },
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSpacing.small),
      ),
    );
  }
}
