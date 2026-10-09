/// Time window covered by the historical price chart.
enum ChartTimeframe {
  oneHour(Duration(hours: 1)),
  fourHours(Duration(hours: 4)),
  oneDay(Duration(days: 1)),
  sevenDays(Duration(days: 7)),
  thirtyDays(Duration(days: 30));

  const ChartTimeframe(this.window);

  final Duration window;

  static const initial = ChartTimeframe.oneDay;
}
