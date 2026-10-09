import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crypto_market_mobile/core/constants/app_routes.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/widgets/skeleton_box.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/models/coin_ticker_state.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/viewmodels/coin_details_view_model.dart';
import 'package:crypto_market_mobile/features/market/data/market_symbols.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_ticker_tile.dart';
import 'package:crypto_market_mobile/features/watchlist/presentation/widgets/watchlist_toggle_button.dart';

/// One saved pair with its latest ticker from the shared market state.
/// Saved pairs stay listed while prices load or are unavailable.
class WatchlistTile extends ConsumerWidget {
  const WatchlistTile({super.key, required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (MarketSymbols.resolve(symbol) == null) {
      return _WatchlistStatusTile(
        symbol: symbol,
        status: AppStrings.watchlistUnsupported,
      );
    }

    void openDetails() => context.push(AppRoutes.coinDetailsLocation(symbol));

    return switch (ref.watch(coinTickerProvider(symbol))) {
      CoinTickerAvailable(:final ticker) => MarketTickerTile(
        ticker: ticker,
        onTap: openDetails,
        trailing: WatchlistToggleButton(symbol: symbol),
      ),
      CoinTickerLoading() => _WatchlistStatusTile(
        symbol: symbol,
        status: AppStrings.watchlistPriceLoading,
        isLoading: true,
        onTap: openDetails,
      ),
      CoinTickerUnavailable() => _WatchlistStatusTile(
        symbol: symbol,
        status: AppStrings.watchlistPriceUnavailable,
        onTap: openDetails,
      ),
    };
  }
}

class _WatchlistStatusTile extends StatelessWidget {
  const _WatchlistStatusTile({
    required this.symbol,
    required this.status,
    this.isLoading = false,
    this.onTap,
  });

  final String symbol;
  final String status;
  final bool isLoading;
  final VoidCallback? onTap;

  static const double _skeletonHeight = 14;
  static const double _skeletonWidth = 120;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              container: true,
              button: onTap != null,
              onTap: onTap,
              label: AppStrings.watchlistStatusSemantics(symbol, status),
              child: ExcludeSemantics(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.medium,
                      AppSpacing.medium,
                      AppSpacing.xSmall,
                      AppSpacing.medium,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          symbol,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xSmall),
                        if (isLoading)
                          const SkeletonBox(
                            height: _skeletonHeight,
                            width: _skeletonWidth,
                          )
                        else
                          Text(
                            status,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          WatchlistToggleButton(symbol: symbol),
        ],
      ),
    );
  }
}
