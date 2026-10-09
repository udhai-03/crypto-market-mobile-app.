import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/utils/date_formatters.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/models/chart_timeframe.dart';

extension ChartTimeframeLabels on ChartTimeframe {
  String get label => switch (this) {
    ChartTimeframe.oneHour => AppStrings.timeframeOneHour,
    ChartTimeframe.fourHours => AppStrings.timeframeFourHours,
    ChartTimeframe.oneDay => AppStrings.timeframeOneDay,
    ChartTimeframe.sevenDays => AppStrings.timeframeSevenDays,
    ChartTimeframe.thirtyDays => AppStrings.timeframeThirtyDays,
  };

  /// Time-axis label: clock time within a day, calendar day beyond.
  String axisLabel(DateTime localTime) {
    return window <= const Duration(days: 1)
        ? DateFormatters.time(localTime)
        : DateFormatters.dayMonth(localTime);
  }
}
