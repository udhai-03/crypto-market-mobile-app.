import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/core/utils/number_formatters.dart';

void main() {
  test('formats prices with precision based on magnitude', () {
    expect(NumberFormatters.price(80600.01), r'$80,600.01');
    expect(NumberFormatters.price(2414.46), r'$2,414.46');
    expect(NumberFormatters.price(0.2249), r'$0.2249');
    expect(NumberFormatters.price(0.00001234), r'$0.00001234');
  });

  test('formats volume in compact units', () {
    expect(NumberFormatters.compactNumber(1.71e9), '1.71B');
    expect(NumberFormatters.compactNumber(975.69e6), '975.69M');
    expect(NumberFormatters.compactNumber(512), '512.00');
    expect(NumberFormatters.compactNumber(0), '0.00');
    expect(NumberFormatters.compactNumber(2.5e13), '25.00T');
  });

  test('values that round up use the next compact unit', () {
    expect(NumberFormatters.compactNumber(999.996), '1.00K');
    expect(NumberFormatters.compactNumber(999999), '1.00M');
    expect(NumberFormatters.compactNumber(999994), '999.99K');
    expect(NumberFormatters.compactNumber(-999999), '-1.00M');
  });

  test('keeps tiny and negative prices readable', () {
    expect(NumberFormatters.price(0), r'$0.00');
    expect(NumberFormatters.price(0.000000016), r'$0.00000002');
    expect(NumberFormatters.price(1e12), r'$1,000,000,000,000.00');
    expect(NumberFormatters.percentChange(-0.004), '-0.00%');
  });

  test('formats percentage change with an explicit sign', () {
    expect(NumberFormatters.percentChange(2.1), '+2.10%');
    expect(NumberFormatters.percentChange(-3.3), '-3.30%');
    expect(NumberFormatters.percentChange(0), '0.00%');
  });

  test('formats signed price changes with the asset price precision', () {
    expect(
      NumberFormatters.signedPrice(1234.5, precisionOf: 80600),
      r'+$1,234.50',
    );
    expect(NumberFormatters.signedPrice(0.5, precisionOf: 80600), r'+$0.50');
    expect(
      NumberFormatters.signedPrice(-0.0012, precisionOf: 0.12),
      r'-$0.0012',
    );
    expect(NumberFormatters.signedPrice(0, precisionOf: 2414), r'$0.00');
  });

  test('formats compact numbers without a currency symbol', () {
    expect(NumberFormatters.compactNumber(12345.6), '12.35K');
    expect(NumberFormatters.compactNumber(42), '42.00');
  });

  test('formats short axis prices by magnitude', () {
    expect(NumberFormatters.axisPrice(80615.4), '80,615');
    expect(NumberFormatters.axisPrice(721.06), '721.06');
    expect(NumberFormatters.axisPrice(0.2249), '0.2249');
    expect(NumberFormatters.axisPrice(0.0000123), '0.000012');
  });
}
