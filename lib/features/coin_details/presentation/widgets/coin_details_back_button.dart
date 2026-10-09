import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:crypto_market_mobile/core/constants/app_routes.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';

/// Pops back to the previous screen, or opens Markets when the details page
/// was opened directly (e.g. from a deep link) with nothing to pop.
class CoinDetailsBackButton extends StatelessWidget {
  const CoinDetailsBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppStrings.backTooltip,
      icon: const BackButtonIcon(),
      onPressed: () =>
          context.canPop() ? context.pop() : context.go(AppRoutes.marketPath),
    );
  }
}
