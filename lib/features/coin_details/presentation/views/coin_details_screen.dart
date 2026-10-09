import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/widgets/coin_chart_section.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/widgets/coin_details_back_button.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/widgets/coin_market_stats.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/widgets/coin_price_summary.dart';
import 'package:crypto_market_mobile/features/market/domain/models/trading_pair.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/live_status_indicator.dart';
import 'package:crypto_market_mobile/features/watchlist/presentation/widgets/watchlist_toggle_button.dart';

/// Price, history chart, and 24h statistics for one tracked [symbol].
class CoinDetailsScreen extends StatelessWidget {
  const CoinDetailsScreen({super.key, required this.symbol});

  /// A tracked Binance symbol, e.g. `BTCUSDT`.
  final String symbol;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CoinDetailsBackButton(),
        title: Text(TradingPair.fromSymbol(symbol).displayName),
        actions: [
          WatchlistToggleButton(symbol: symbol),
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.medium),
            child: Center(child: LiveStatusIndicator()),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.medium,
            AppSpacing.small,
            AppSpacing.medium,
            AppSpacing.screen,
          ),
          children: [
            CoinPriceSummary(symbol: symbol),
            const SizedBox(height: AppSpacing.screen),
            CoinChartSection(symbol: symbol),
            const SizedBox(height: AppSpacing.screen),
            CoinMarketStats(symbol: symbol),
          ],
        ),
      ),
    );
  }
}
