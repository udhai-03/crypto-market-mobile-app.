import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/core/network/binance_api.dart';
import 'package:crypto_market_mobile/core/network/binance_dio_provider.dart';
import 'package:crypto_market_mobile/core/network/web_socket_connection.dart';
import 'package:crypto_market_mobile/features/market/data/datasources/binance_remote_data_source.dart';
import 'package:crypto_market_mobile/features/market/data/datasources/binance_ticker_stream_service.dart';
import 'package:crypto_market_mobile/features/market/data/market_symbols.dart';
import 'package:crypto_market_mobile/features/market/data/repositories/binance_market_repository.dart';
import 'package:crypto_market_mobile/features/market/domain/repositories/market_repository.dart';

final binanceRemoteDataSourceProvider = Provider<BinanceRemoteDataSource>((
  ref,
) {
  return BinanceRemoteDataSource(ref.watch(binanceDioProvider));
});

final binanceTickerStreamServiceProvider = Provider<BinanceTickerStreamService>(
  (ref) {
    final service = BinanceTickerStreamService(
      symbols: MarketSymbols.tracked,
      connect: (uri) => IoWebSocketConnection.connect(
        uri,
        connectTimeout: BinanceApi.connectTimeout,
        pingInterval: BinanceApi.webSocketPingInterval,
      ),
    );
    ref.onDispose(service.dispose);
    return service;
  },
);

final marketRepositoryProvider = Provider<MarketRepository>((ref) {
  return BinanceMarketRepository(
    ref.watch(binanceRemoteDataSourceProvider),
    ref.watch(binanceTickerStreamServiceProvider),
  );
});
