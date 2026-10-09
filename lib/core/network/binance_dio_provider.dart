import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:crypto_market_mobile/core/network/binance_api.dart';

final binanceDioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: BinanceApi.baseUrl,
      connectTimeout: BinanceApi.connectTimeout,
      receiveTimeout: BinanceApi.receiveTimeout,
      responseType: ResponseType.json,
    ),
  );

  ref.onDispose(dio.close);
  return dio;
});
