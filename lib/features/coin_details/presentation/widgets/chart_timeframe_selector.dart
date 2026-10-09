import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/models/chart_timeframe.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/models/chart_timeframe_labels.dart';

class ChartTimeframeSelector extends StatelessWidget {
  const ChartTimeframeSelector({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ChartTimeframe selected;
  final ValueChanged<ChartTimeframe> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.timeframeSelectorLabel,
      child: SegmentedButton<ChartTimeframe>(
        expandedInsets: EdgeInsets.zero,
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xSmall),
        ),
        segments: [
          for (final timeframe in ChartTimeframe.values)
            ButtonSegment(value: timeframe, label: Text(timeframe.label)),
        ],
        selected: {selected},
        onSelectionChanged: (selection) => onSelected(selection.single),
      ),
    );
  }
}
