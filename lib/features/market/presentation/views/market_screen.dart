import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/core/widgets/fade_slide_in.dart';
import 'package:crypto_market_mobile/features/market/domain/models/market_ticker.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_view_model.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_controls.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_header.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_state_views.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_summary_section.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/market_ticker_list.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: () =>
          ref.read(marketViewModelProvider.notifier).pauseLiveUpdates(),
      onResume: () =>
          ref.read(marketViewModelProvider.notifier).resumeLiveUpdates(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final marketState = ref.watch(marketViewModelProvider);
    final viewModel = ref.read(marketViewModelProvider.notifier);

    ref.listen(marketViewModelProvider, (previous, next) {
      if (next case AsyncError(hasValue: true)) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text(AppStrings.marketRefreshFailed)),
          );
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              const SliverToBoxAdapter(child: MarketHeader()),
              ..._contentSlivers(marketState, viewModel),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _contentSlivers(
    AsyncValue<List<MarketTicker>> marketState,
    MarketViewModel viewModel,
  ) {
    return switch (marketState) {
      AsyncValue(:final value?) when value.isNotEmpty => const [
        SliverToBoxAdapter(child: FadeSlideIn(child: MarketControls())),
        SliverToBoxAdapter(
          child: FadeSlideIn(index: 1, child: MarketSummarySection()),
        ),
        MarketListHeader(),
        MarketTickerList(),
      ],
      AsyncValue(hasValue: true, isLoading: false) => [
        MarketMessageSliver(
          icon: Icons.inbox_outlined,
          title: AppStrings.marketEmptyTitle,
          message: AppStrings.marketEmpty,
          actionLabel: AppStrings.refresh,
          onAction: viewModel.refresh,
        ),
      ],
      AsyncValue(:final error?, isLoading: false) => [
        MarketMessageSliver(
          icon: Icons.cloud_off_outlined,
          title: AppStrings.errorTitle,
          message: error is AppException
              ? error.message
              : AppStrings.unexpectedError,
          actionLabel: AppStrings.retry,
          onAction: viewModel.refresh,
        ),
      ],
      _ => const [MarketLoadingSliver()],
    };
  }
}
