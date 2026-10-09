import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:crypto_market_mobile/app/theme/app_colors.dart';
import 'package:crypto_market_mobile/core/constants/app_spacing.dart';
import 'package:crypto_market_mobile/core/constants/app_strings.dart';
import 'package:crypto_market_mobile/core/utils/date_formatters.dart';
import 'package:crypto_market_mobile/core/utils/number_formatters.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/models/price_candle.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/models/chart_timeframe_labels.dart';
import 'package:crypto_market_mobile/features/coin_details/presentation/models/price_chart_data.dart';
import 'package:crypto_market_mobile/features/market/presentation/models/price_trend.dart';
import 'package:crypto_market_mobile/features/market/presentation/widgets/price_change_badge.dart';

/// Line chart of closing prices with a readout of the touched candle.
class PriceHistoryChart extends StatefulWidget {
  const PriceHistoryChart({super.key, required this.data});

  /// Must contain at least [PriceChartData.minimumCandles] candles.
  final PriceChartData data;

  static const double chartHeight = 220;

  @override
  State<PriceHistoryChart> createState() => _PriceHistoryChartState();
}

class _PriceHistoryChartState extends State<PriceHistoryChart> {
  static const int _priceLabelIntervals = 4;
  static const int _timeLabelCount = 3;
  static const double _rangePaddingRatio = 0.1;
  static const double _flatRangePaddingRatio = 0.01;
  static const double _zeroPricePadding = 1;
  static const double _priceAxisWidth = 56;
  static const double _timeAxisHeight = 24;
  static const double _touchThreshold = 48;
  static const double _lineWidth = 2;
  static const double _touchDotRadius = 4;
  static const double _areaTopAlpha = 0.24;
  static const List<int> _gridDash = [4, 4];

  final _selectedIndex = ValueNotifier<int?>(null);
  late List<FlSpot> _spots;

  @override
  void initState() {
    super.initState();
    _spots = _buildSpots(widget.data.candles);
  }

  @override
  void didUpdateWidget(PriceHistoryChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      _spots = _buildSpots(widget.data.candles);
      _selectedIndex.value = null;
    }
  }

  @override
  void dispose() {
    _selectedIndex.dispose();
    super.dispose();
  }

  static List<FlSpot> _buildSpots(List<PriceCandle> candles) {
    return [
      for (var i = 0; i < candles.length; i++)
        FlSpot(i.toDouble(), candles[i].close),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final theme = Theme.of(context);
    final axisStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final lineColor = PriceTrend.fromChange(data.changePercentAt(data.last))
        .color;

    final spread = data.maxPrice - data.minPrice;
    final flatPadding = data.maxPrice.abs() * _flatRangePaddingRatio;
    final padding = spread > 0
        ? spread * _rangePaddingRatio
        : (flatPadding > 0 ? flatPadding : _zeroPricePadding);
    final minY = data.minPrice - padding;
    final maxY = data.maxPrice + padding;
    final priceInterval = (maxY - minY) / _priceLabelIntervals;
    final lastIndex = data.candles.length - 1;
    final timeInterval = (lastIndex / _timeLabelCount).ceilToDouble().clamp(
      1.0,
      double.infinity,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ValueListenableBuilder<int?>(
          valueListenable: _selectedIndex,
          builder: (context, index, _) => _ChartReadout(
            data: data,
            selected: index == null ? null : data.candles[index],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Semantics(
          container: true,
          label: AppStrings.chartSemantics(
            timeframe: data.timeframe.label,
            from: NumberFormatters.price(data.first.close),
            to: NumberFormatters.price(data.last.close),
            change: NumberFormatters.percentChange(
              data.changePercentAt(data.last),
            ),
          ),
          child: SizedBox(
            height: PriceHistoryChart.chartHeight,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: lastIndex.toDouble(),
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: priceInterval,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.outline,
                    strokeWidth: 1,
                    dashArray: _gridDash,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: _priceAxisWidth,
                      interval: priceInterval,
                      minIncluded: false,
                      maxIncluded: false,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        meta: meta,
                        child: Text(
                          NumberFormatters.axisPrice(value),
                          style: axisStyle,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: _timeAxisHeight,
                      interval: timeInterval,
                      maxIncluded: false,
                      getTitlesWidget: (value, meta) {
                        final index = value.round();
                        if (index != value || index < 0 || index > lastIndex) {
                          return const SizedBox.shrink();
                        }
                        return SideTitleWidget(
                          meta: meta,
                          fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                          child: Text(
                            data.timeframe.axisLabel(
                              data.candles[index].openTime.toLocal(),
                            ),
                            style: axisStyle,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  touchSpotThreshold: _touchThreshold,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) => [for (final _ in spots) null],
                  ),
                  getTouchedSpotIndicator: (bar, indexes) => [
                    for (final _ in indexes)
                      TouchedSpotIndicatorData(
                        FlLine(
                          color: theme.colorScheme.onSurfaceVariant,
                          strokeWidth: 1,
                        ),
                        FlDotData(
                          getDotPainter: (spot, percent, bar, index) =>
                              FlDotCirclePainter(
                                radius: _touchDotRadius,
                                color: lineColor,
                                strokeWidth: _lineWidth,
                                strokeColor: AppColors.background,
                              ),
                        ),
                      ),
                  ],
                  touchCallback: (event, response) {
                    final spot = response?.lineBarSpots?.firstOrNull;
                    _selectedIndex.value =
                        event.isInterestedForInteractions && spot != null
                        ? spot.spotIndex
                        : null;
                  },
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _spots,
                    color: lineColor,
                    barWidth: _lineWidth,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          lineColor.withValues(alpha: _areaTopAlpha),
                          lineColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Latest close and window change, or the touched candle's details.
/// Always two text lines tall so the chart does not jump while dragging.
class _ChartReadout extends StatelessWidget {
  const _ChartReadout({required this.data, required this.selected});

  final PriceChartData data;
  final PriceCandle? selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final selected = this.selected;
    final candle = selected ?? data.last;

    final caption = selected == null
        ? AppStrings.chartRangeCaption(data.timeframe.label)
        : DateFormatters.dayMonthTime(selected.openTime.toLocal());
    final details = selected == null
        ? AppStrings.chartRangeDetails(
            high: NumberFormatters.price(data.highPrice),
            low: NumberFormatters.price(data.lowPrice),
          )
        : AppStrings.chartCandleDetails(
            open: NumberFormatters.price(selected.open),
            high: NumberFormatters.price(selected.high),
            low: NumberFormatters.price(selected.low),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                NumberFormatters.price(candle.close),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.small),
            PriceChangeBadge(percent: data.changePercentAt(candle)),
          ],
        ),
        const SizedBox(height: AppSpacing.xSmall),
        Text(
          caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: mutedStyle,
        ),
        Text(
          details,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: mutedStyle,
        ),
      ],
    );
  }
}
