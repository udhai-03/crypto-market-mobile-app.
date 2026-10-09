import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/core/utils/date_formatters.dart';

void main() {
  final value = DateTime(2026, 10, 9, 9, 5);

  test('formats clock time with leading zeros', () {
    expect(DateFormatters.time(value), '09:05');
  });

  test('formats day and abbreviated month', () {
    expect(DateFormatters.dayMonth(value), '9 Oct');
    expect(DateFormatters.dayMonth(DateTime(2026, 1, 31)), '31 Jan');
  });

  test('combines day, month and time', () {
    expect(DateFormatters.dayMonthTime(value), '9 Oct, 09:05');
  });
}
