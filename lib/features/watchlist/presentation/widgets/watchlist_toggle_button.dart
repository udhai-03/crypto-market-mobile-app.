import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/app/theme/app_colors.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/features/watchlist/presentation/viewmodels/watchlist_view_model.dart';

/// Star that adds [symbol] to, or removes it from, the watchlist.
/// Disabled while the watchlist is loading or unreadable.
class WatchlistToggleButton extends ConsumerWidget {
  const WatchlistToggleButton({super.key, required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaved = ref.watch(watchlistMembershipProvider(symbol));

    return IconButton(
      tooltip: switch (isSaved) {
        true => AppStrings.removeFromWatchlist(symbol),
        false => AppStrings.addToWatchlist(symbol),
        null => AppStrings.watchlistControlUnavailable,
      },
      isSelected: isSaved ?? false,
      icon: const Icon(Icons.star_border),
      selectedIcon: const Icon(Icons.star, color: AppColors.favorite),
      onPressed: isSaved == null ? null : () => _toggle(context, ref),
    );
  }

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await ref
        .read(watchlistViewModelProvider.notifier)
        .toggle(symbol);
    if (saved) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(AppStrings.watchlistWriteError)),
      );
  }
}
