import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';

import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/core/network/binance_api.dart';
import 'package:crypto_market_mobile/core/network/dio_exception_mapper.dart';
import 'package:crypto_market_mobile/features/market/data/models/binance_kline_dto.dart';
import 'package:crypto_market_mobile/features/market/data/models/binance_ticker_dto.dart';

class BinanceRemoteDataSource {
  const BinanceRemoteDataSource(this._dio);

  final Dio _dio;

  static const _logName = 'BinanceRemoteDataSource';

  /// Throws an [AppException] when the request or response parsing fails.
  Future<List<BinanceTickerDto>> fetch24hTickers(List<String> symbols) async {
    final data = await _get(
      BinanceApi.ticker24hPath,
      queryParameters: {BinanceApi.symbolsQueryParam: jsonEncode(symbols)},
    );
    return _parseTickers(data);
  }

  /// Historical candles in the order Binance returns them.
  ///
  /// Malformed records are skipped so one bad candle does not hide the rest
  /// of the history. Throws an [AppException] when the request fails, the
  /// body is not a list, or no record in a non-empty body is valid.
  Future<List<BinanceKlineDto>> fetchKlines({
    required String symbol,
    required String interval,
    required int limit,
  }) async {
    final data = await _get(
      BinanceApi.klinesPath,
      queryParameters: {
        BinanceApi.symbolQueryParam: symbol,
        BinanceApi.intervalQueryParam: interval,
        BinanceApi.limitQueryParam: limit,
      },
    );
    return _parseKlines(data);
  }

  Future<Object?> _get(
    String path, {
    required Map<String, Object> queryParameters,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (exception) {
      throw mapDioException(exception);
    }
  }

  List<BinanceTickerDto> _parseTickers(Object? data) {
    if (data is! List<Object?>) throw const InvalidResponseException();

    try {
      return [
        for (final item in data)
          if (item is Map<String, dynamic>)
            BinanceTickerDto.fromJson(item)
          else
            throw const FormatException('Binance ticker is not an object'),
      ];
    } on FormatException {
      throw const InvalidResponseException();
    }
  }

  List<BinanceKlineDto> _parseKlines(Object? data) {
    if (data is! List<Object?>) throw const InvalidResponseException();

    final klines = <BinanceKlineDto>[];
    for (final item in data) {
      try {
        klines.add(BinanceKlineDto.fromJson(item));
      } on FormatException catch (error) {
        log('Skipped malformed kline', name: _logName, error: error);
      }
    }

    if (data.isNotEmpty && klines.isEmpty) {
      throw const InvalidResponseException();
    }
    return klines;
  }
}
