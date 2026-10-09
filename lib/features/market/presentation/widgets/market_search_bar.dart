import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/app/theme/app_colors.dart';
import 'package:crypto_market_mobile/core/constants/app_radius.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/features/market/presentation/viewmodels/market_query_view_model.dart';

class MarketSearchBar extends ConsumerStatefulWidget {
  const MarketSearchBar({super.key});

  @override
  ConsumerState<MarketSearchBar> createState() => _MarketSearchBarState();
}

class _MarketSearchBarState extends ConsumerState<MarketSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(marketQueryProvider).searchText,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final queryViewModel = ref.read(marketQueryProvider.notifier);

    ref.listen(marketQueryProvider.select((query) => query.searchText), (
      _,
      searchText,
    ) {
      if (_controller.text != searchText) _controller.text = searchText;
    });

    final theme = Theme.of(context);
    final pill = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      borderSide: const BorderSide(color: AppColors.glassBorder),
    );

    return TextField(
      controller: _controller,
      onChanged: queryViewModel.updateSearch,
      textInputAction: TextInputAction.search,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      enableSuggestions: false,
      cursorColor: theme.colorScheme.primary,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
        letterSpacing: 0.4,
      ),
      decoration: InputDecoration(
        hintText: AppStrings.searchHint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        filled: true,
        fillColor: AppColors.glassFill,
        border: pill,
        enabledBorder: pill,
        focusedBorder: pill.copyWith(
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.6),
          ),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: AppStrings.clearSearch,
              icon: const Icon(Icons.cancel_rounded, size: 18),
              color: theme.colorScheme.onSurfaceVariant,
              onPressed: () => queryViewModel.updateSearch(''),
            );
          },
        ),
      ),
    );
  }
}
