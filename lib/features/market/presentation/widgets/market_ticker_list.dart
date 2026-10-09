import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crypto_market_mobile/core/constants/app_routes.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/widgets/fade_slide_in.dart';
import 'package:crypto_market_mobile/core/widgets/intro_window.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_query_view_model.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_selectors.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_state_views.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_ticker_tile.dart';
import 'package:crypto_market_mobile/features/watchlist/presentation/widgets/watchlist_toggle_button.dart';

/// Sliver showing the searched, filtered, and sorted market tickers.
class MarketTickerList extends ConsumerStatefulWidget {
  const MarketTickerList({super.key});

  @override
  ConsumerState<MarketTickerList> createState() => _MarketTickerListState();
}

class _MarketTickerListState extends ConsumerState<MarketTickerList> {
  /// Aligns dividers with the pair text, past the coin avatar.
  static const double _dividerIndent = 64;

  final _intro = IntroWindow();

  @override
  Widget build(BuildContext context) {
    final tickers = ref.watch(visibleMarketTickersProvider);

    if (tickers.isEmpty) {
      return MarketMessageSliver(
        icon: Icons.search_off_rounded,
        title: AppStrings.noResultsTitle,
        message: AppStrings.noResultsMessage,
        actionLabel: AppStrings.clearSearchAndFilter,
        onAction: ref.read(marketQueryProvider.notifier).clearSearchAndFilter,
      );
    }

    final indexBySymbol = {
      for (var i = 0; i < tickers.length; i++) tickers[i].symbol: i,
    };

    return SliverPadding(
      padding: EdgeInsets.only(
        bottom: AppSpacing.screen + MediaQuery.paddingOf(context).bottom,
      ),
      sliver: SliverList.builder(
        itemCount: tickers.length,
        findChildIndexCallback: (key) =>
            key is ValueKey<String> ? indexBySymbol[key.value] : null,
        itemBuilder: (context, index) {
          final ticker = tickers[index];
          return FadeSlideIn(
            key: ValueKey(ticker.symbol),
            index: index,
            animate: _intro.isOpen,
            child: Column(
              children: [
                MarketTickerTile(
                  ticker: ticker,
                  onTap: () => context.push(
                    AppRoutes.coinDetailsLocation(ticker.symbol),
                  ),
                  trailing: WatchlistToggleButton(symbol: ticker.symbol),
                ),
                if (index < tickers.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: _dividerIndent,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
