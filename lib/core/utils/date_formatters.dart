/// Compact, locale-independent date and time labels.
///
/// Callers decide the time zone; pass `toLocal()` values for display.
abstract final class DateFormatters {
  static const _monthAbbreviations = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// `09:05`
  static String time(DateTime value) {
    return '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';
  }

  /// `9 Oct`
  static String dayMonth(DateTime value) {
    return '${value.day} ${_monthAbbreviations[value.month - 1]}';
  }

  /// `9 Oct, 09:05`
  static String dayMonthTime(DateTime value) {
    return '${dayMonth(value)}, ${time(value)}';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
