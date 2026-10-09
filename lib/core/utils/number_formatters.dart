abstract final class NumberFormatters {
  static const _currencySymbol = r'$';
  static final _thousandsGroup = RegExp(r'\B(?=(\d{3})+(?!\d))');
  static const _compactUnits = <(double, String)>[
    (1e12, 'T'),
    (1e9, 'B'),
    (1e6, 'M'),
    (1e3, 'K'),
  ];

  /// Values this close below a unit would print as `1000.00` of the smaller
  /// unit after rounding to two decimals, so they use the larger unit.
  static const _roundsToNextUnit = 0.999995;

  /// More decimals for low-priced assets so small moves stay visible.
  static String price(double value) {
    final digits = value.toStringAsFixed(_priceDecimals(value));
    return '$_currencySymbol${_groupThousands(digits)}';
  }

  /// Price change with an explicit sign, e.g. `+$1,234.50` or `-$0.0012`,
  /// using the decimals of [precisionOf] (typically the asset's price).
  static String signedPrice(double value, {required double precisionOf}) {
    final sign = switch (value) {
      > 0 => '+',
      < 0 => '-',
      _ => '',
    };
    final digits = value.abs().toStringAsFixed(_priceDecimals(precisionOf));
    return '$sign$_currencySymbol${_groupThousands(digits)}';
  }

  /// Short chart-axis price without the currency symbol, e.g. `80,615`.
  static String axisPrice(double value) {
    final decimals = switch (value.abs()) {
      >= 1000 => 0,
      >= 1 => 2,
      >= 0.01 => 4,
      _ => 6,
    };
    return _groupThousands(value.toStringAsFixed(decimals));
  }

  static String percentChange(double value) {
    final sign = value > 0 ? '+' : '';
    return '$sign${value.toStringAsFixed(2)}%';
  }

  static String compactNumber(double value) {
    for (final (threshold, suffix) in _compactUnits) {
      if (value.abs() >= threshold * _roundsToNextUnit) {
        return '${(value / threshold).toStringAsFixed(2)}$suffix';
      }
    }
    return value.toStringAsFixed(2);
  }

  static int _priceDecimals(double value) {
    return switch (value.abs()) {
      >= 1 || 0.0 => 2,
      >= 0.01 => 4,
      _ => 8,
    };
  }

  static String _groupThousands(String fixed) {
    final [whole, ...fraction] = fixed.split('.');
    final grouped = whole.replaceAll(_thousandsGroup, ',');
    return fraction.isEmpty ? grouped : '$grouped.${fraction.first}';
  }
}
