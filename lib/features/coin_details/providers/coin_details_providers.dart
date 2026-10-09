import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/features/coin_details/data/repositories/binance_chart_repository.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/repositories/chart_repository.dart';
import 'package:crypto_market_mobile/features/market/providers/market_providers.dart';

final chartRepositoryProvider = Provider<ChartRepository>((ref) {
  return BinanceChartRepository(ref.watch(binanceRemoteDataSourceProvider));
});
