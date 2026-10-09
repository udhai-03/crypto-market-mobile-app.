import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:crypto_market_mobile/core/constants/app_routes.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/core/widgets/fade_slide_in.dart';
import 'package:crypto_market_mobile/core/widgets/intro_window.dart';
import 'package:crypto_market_mobile/core/widgets/skeleton_box.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_view_model.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_header.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_state_views.dart';
import 'package:crypto_market_mobile/features/watchlist/presentation/viewmodels/watchlist_view_model.dart';
import 'package:crypto_market_mobile/features/watchlist/presentation/widgets/watchlist_tile.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: ref.read(marketViewModelProvider.notifier).refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverToBoxAdapter(
                child: MarketHeader(
                  title: AppStrings.watchlistTitle,
                  subtitle: AppStrings.watchlistSubtitle,
                ),
              ),
              switch (watchlist) {
                AsyncValue(:final value?) when value.isNotEmpty =>
                  _WatchlistList(symbols: value),
                AsyncValue(hasValue: true, isLoading: false) =>
                  MarketMessageSliver(
                    icon: Icons.star_outline_rounded,
                    title: AppStrings.watchlistEmptyTitle,
                    message: AppStrings.watchlistEmptyMessage,
                    actionLabel: AppStrings.browseMarkets,
                    onAction: () => context.go(AppRoutes.marketPath),
                  ),
                AsyncValue(:final error?, isLoading: false) =>
                  MarketMessageSliver(
                    icon: Icons.error_outline,
                    title: AppStrings.watchlistLoadErrorTitle,
                    message: error is AppException
                        ? error.message
                        : AppStrings.watchlistReadError,
                    actionLabel: AppStrings.retry,
                    onAction: ref
                        .read(watchlistViewModelProvider.notifier)
                        .reload,
                  ),
                _ => const _WatchlistLoading(),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchlistList extends StatefulWidget {
  const _WatchlistList({required this.symbols});

  final List<String> symbols;

  @override
  State<_WatchlistList> createState() => _WatchlistListState();
}

class _WatchlistListState extends State<_WatchlistList> {
  /// Aligns dividers with the pair text, past the coin avatar.
  static const double _dividerIndent = 64;

  final _intro = IntroWindow();

  @override
  Widget build(BuildContext context) {
    final symbols = widget.symbols;

    return SliverPadding(
      padding: EdgeInsets.only(
        bottom: AppSpacing.screen + MediaQuery.paddingOf(context).bottom,
      ),
      sliver: SliverList.separated(
        itemCount: symbols.length,
        itemBuilder: (context, index) {
          final symbol = symbols[index];
          return FadeSlideIn(
            key: ValueKey(symbol),
            index: index,
            animate: _intro.isOpen,
            child: WatchlistTile(symbol: symbol),
          );
        },
        separatorBuilder: (context, index) =>
            const Divider(height: 1, thickness: 1, indent: _dividerIndent),
      ),
    );
  }
}

class _WatchlistLoading extends StatelessWidget {
  const _WatchlistLoading();

  static const double _tileHeight = 72;
  static const int _placeholderTiles = 3;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
      sliver: SliverToBoxAdapter(
        child: Semantics(
          label: AppStrings.watchlistLoading,
          child: ExcludeSemantics(
            child: Column(
              children: [
                for (var i = 0; i < _placeholderTiles; i++) ...const [
                  SkeletonBox(height: _tileHeight),
                  SizedBox(height: AppSpacing.small),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
