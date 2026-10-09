import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:crypto_market_mobile/core/constants/app_routes.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/widgets/status_message_view.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/widgets/coin_details_back_button.dart';

/// Shown when the Coin Details route has a missing or untracked symbol.
class CoinNotFoundScreen extends StatelessWidget {
  const CoinNotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CoinDetailsBackButton(),
        title: const Text(AppStrings.coinDetails),
      ),
      body: StatusMessageView(
        icon: Icons.search_off,
        title: AppStrings.coinNotFoundTitle,
        message: AppStrings.coinNotFoundMessage,
        actionLabel: AppStrings.backToMarkets,
        onAction: () => context.go(AppRoutes.marketPath),
      ),
    );
  }
}
