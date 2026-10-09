import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/app/app.dart';

void main() {
  runApp(const ProviderScope(child: CryptoMarketApp()));
}
