import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    return TextField(
      controller: _controller,
      onChanged: queryViewModel.updateSearch,
      textInputAction: TextInputAction.search,
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        hintText: AppStrings.searchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: AppStrings.clearSearch,
              icon: const Icon(Icons.close),
              onPressed: () => queryViewModel.updateSearch(''),
            );
          },
        ),
      ),
    );
  }
}
