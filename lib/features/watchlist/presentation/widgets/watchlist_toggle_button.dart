import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/app/theme/app_colors.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/features/watchlist/presentation/viewmodels/watchlist_view_model.dart';

/// Modern interactive button that adds [symbol] to, or removes it from, the watchlist.
/// Features a subtle glass backdrop, amber accent, and status tooltips.
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
      onPressed: isSaved == null ? null : () => _toggle(context, ref),
      style: IconButton.styleFrom(
        backgroundColor: isSaved == true
            ? const Color(0x22FBBF24)
            : const Color(0x0CFFFFFF),
        foregroundColor: isSaved == true
            ? AppColors.favorite
            : AppColors.outlineStrong,
        side: BorderSide(
          color: isSaved == true
              ? const Color(0x55FBBF24)
              : const Color(0x18FFFFFF),
          width: 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(7),
        minimumSize: const Size(36, 36),
        maximumSize: const Size(40, 40),
      ),
      icon: const Icon(Icons.star_outline_rounded, size: 20),
      selectedIcon: const Icon(
        Icons.star_rounded,
        size: 20,
        color: AppColors.favorite,
      ),
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
