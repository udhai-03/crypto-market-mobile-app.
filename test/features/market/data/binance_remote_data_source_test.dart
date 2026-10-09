import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/core/network/binance_api.dart';
import 'package:crypto_market_mobile/features/market/data/datasources/binance_remote_data_source.dart';

void main() {
  late Dio dio;
  late BinanceRemoteDataSource dataSource;
  RequestOptions? lastRequest;

  void respondWith(
    void Function(RequestOptions, RequestInterceptorHandler) onRequest,
  ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          lastRequest = options;
          onRequest(options, handler);
        },
      ),
    );
  }

  void rejectWith(DioExceptionType type, {int? statusCode}) {
    respondWith((options, handler) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: type,
          response: statusCode == null
              ? null
              : Response<Object?>(
                  requestOptions: options,
                  statusCode: statusCode,
                ),
        ),
      );
    });
  }

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: BinanceApi.baseUrl));
    dataSource = BinanceRemoteDataSource(dio);
    lastRequest = null;
  });

  test('requests the 24hr ticker endpoint and parses tickers', () async {
    respondWith((options, handler) {
      handler.resolve(
        Response<Object?>(
          requestOptions: options,
          statusCode: 200,
          data: [
            {
              'symbol': 'ETHUSDT',
              'lastPrice': '2416.44000000',
              'priceChange': '-139.84000000',
              'priceChangePercent': '-5.470',
              'highPrice': '2587.28000000',
              'lowPrice': '2406.11000000',
              'volume': '388891.58330000',
              'quoteVolume': '977723596.73170000',
              'closeTime': 1791544672007,
            },
          ],
        ),
      );
    });

    final tickers = await dataSource.fetch24hTickers(['ETHUSDT']);

    expect(lastRequest?.path, BinanceApi.ticker24hPath);
    expect(
      lastRequest?.queryParameters[BinanceApi.symbolsQueryParam],
      jsonEncode(['ETHUSDT']),
    );
    expect(tickers.single.symbol, 'ETHUSDT');
    expect(tickers.single.lastPrice, 2416.44);
  });

  test('throws InvalidResponseException for a non-list body', () {
    respondWith((options, handler) {
      handler.resolve(
        Response<Object?>(
          requestOptions: options,
          statusCode: 200,
          data: {'code': -1121},
        ),
      );
    });

    expect(
      dataSource.fetch24hTickers(['BTCUSDT']),
      throwsA(isA<InvalidResponseException>()),
    );
  });

  test('throws InvalidResponseException for malformed tickers', () {
    respondWith((options, handler) {
      handler.resolve(
        Response<Object?>(
          requestOptions: options,
          statusCode: 200,
          data: [
            {'symbol': 'BTCUSDT', 'lastPrice': 'not-a-number'},
          ],
        ),
      );
    });

    expect(
      dataSource.fetch24hTickers(['BTCUSDT']),
      throwsA(isA<InvalidResponseException>()),
    );
  });

  test('maps connection errors to NoConnectionException', () {
    rejectWith(DioExceptionType.connectionError);

    expect(
      dataSource.fetch24hTickers(['BTCUSDT']),
      throwsA(isA<NoConnectionException>()),
    );
  });

  test('maps timeouts to RequestTimeoutException', () {
    rejectWith(DioExceptionType.receiveTimeout);

    expect(
      dataSource.fetch24hTickers(['BTCUSDT']),
      throwsA(isA<RequestTimeoutException>()),
    );
  });

  test('maps HTTP errors to ServerException with the status code', () {
    rejectWith(DioExceptionType.badResponse, statusCode: 400);

    expect(
      dataSource.fetch24hTickers(['BTCUSDT']),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'statusCode', 400),
      ),
    );
  });
}
