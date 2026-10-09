import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crypto_market_mobile/core/errors/app_exception.dart';
import 'package:crypto_market_mobile/core/network/binance_api.dart';
import 'package:crypto_market_mobile/features/coin_details/data/repositories/binance_chart_repository.dart';
import 'package:crypto_market_mobile/features/coin_details/domain/models/chart_timeframe.dart';
import 'package:crypto_market_mobile/features/market/data/datasources/binance_remote_data_source.dart';

import '../../../helpers/kline_fixtures.dart';

void main() {
  late Dio dio;
  late BinanceChartRepository repository;
  RequestOptions? lastRequest;

  void respondWith(Object? body) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          lastRequest = options;
          handler.resolve(
            Response<Object?>(
              requestOptions: options,
              statusCode: 200,
              data: body,
            ),
          );
        },
      ),
    );
  }

  void rejectWith(DioExceptionType type, {int? statusCode}) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          lastRequest = options;
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
        },
      ),
    );
  }

  Future<void> loadCandles({
    String symbol = 'ETHUSDT',
    ChartTimeframe timeframe = ChartTimeframe.oneDay,
  }) {
    return repository.getCandles(symbol: symbol, timeframe: timeframe);
  }

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: BinanceApi.baseUrl));
    repository = BinanceChartRepository(BinanceRemoteDataSource(dio));
    lastRequest = null;
  });

  test(
    'requests the klines endpoint with symbol, interval and limit',
    () async {
      respondWith([klineRecord()]);

      await loadCandles(symbol: 'SOLUSDT', timeframe: ChartTimeframe.sevenDays);

      expect(lastRequest?.path, BinanceApi.klinesPath);
      expect(lastRequest?.queryParameters, {
        BinanceApi.symbolQueryParam: 'SOLUSDT',
        BinanceApi.intervalQueryParam: '1h',
        BinanceApi.limitQueryParam: 168,
      });
    },
  );

  test('maps every timeframe to its interval and candle count', () async {
    const expected = {
      ChartTimeframe.oneHour: ('1m', 60),
      ChartTimeframe.fourHours: ('5m', 48),
      ChartTimeframe.oneDay: ('15m', 96),
      ChartTimeframe.sevenDays: ('1h', 168),
      ChartTimeframe.thirtyDays: ('4h', 180),
    };
    respondWith(const <Object?>[]);

    for (final MapEntry(key: timeframe, value: (interval, limit))
        in expected.entries) {
      await loadCandles(timeframe: timeframe);

      expect(
        lastRequest?.queryParameters[BinanceApi.intervalQueryParam],
        interval,
      );
      expect(lastRequest?.queryParameters[BinanceApi.limitQueryParam], limit);
    }
  });

  test('every timeframe request covers its whole window', () {
    const intervalDurations = {
      '1m': Duration(minutes: 1),
      '5m': Duration(minutes: 5),
      '15m': Duration(minutes: 15),
      '1h': Duration(hours: 1),
      '4h': Duration(hours: 4),
    };

    for (final timeframe in ChartTimeframe.values) {
      final request = BinanceChartRepository.requestFor(timeframe);
      expect(
        intervalDurations[request.interval]! * request.limit,
        timeframe.window,
        reason: timeframe.name,
      );
    }
  });

  test('parses candles and returns them oldest first', () async {
    respondWith([
      klineRecord(openTime: 1791540000000, closeTime: 1791543599999),
      klineRecord(),
    ]);

    final candles = await repository.getCandles(
      symbol: 'BTCUSDT',
      timeframe: ChartTimeframe.sevenDays,
    );

    expect(candles, hasLength(2));
    expect(candles.first.openTime, DateTime.utc(2026, 10, 9, 9));
    expect(candles.last.openTime, DateTime.utc(2026, 10, 9, 10));
    expect(candles.first.close, 82658.01);
    expect(candles.first.quoteVolume, 23462671.9723081);
  });

  test('returns fewer candles than requested when Binance does', () async {
    respondWith([klineRecord()]);

    final candles = await repository.getCandles(
      symbol: 'BTCUSDT',
      timeframe: ChartTimeframe.thirtyDays,
    );

    expect(candles, hasLength(1));
  });

  test('returns an empty list for an empty response', () async {
    respondWith(const <Object?>[]);

    final candles = await repository.getCandles(
      symbol: 'BTCUSDT',
      timeframe: ChartTimeframe.oneHour,
    );

    expect(candles, isEmpty);
  });

  test('skips malformed records but keeps valid ones', () async {
    respondWith([
      klineRecord(),
      const ['broken'],
      klineRecord(close: 'oops'),
    ]);

    final candles = await repository.getCandles(
      symbol: 'BTCUSDT',
      timeframe: ChartTimeframe.oneHour,
    );

    expect(candles, hasLength(1));
  });

  test('throws InvalidResponseException when no record is valid', () {
    respondWith([
      const ['broken'],
    ]);

    expect(loadCandles(), throwsA(isA<InvalidResponseException>()));
  });

  test('throws InvalidResponseException for a non-list body', () {
    respondWith({'code': -1121, 'msg': 'Invalid symbol.'});

    expect(loadCandles(), throwsA(isA<InvalidResponseException>()));
  });

  test('maps HTTP errors to ServerException', () {
    rejectWith(DioExceptionType.badResponse, statusCode: 400);

    expect(
      loadCandles(),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'statusCode', 400),
      ),
    );
  });

  test('maps timeouts to RequestTimeoutException', () {
    rejectWith(DioExceptionType.receiveTimeout);

    expect(loadCandles(), throwsA(isA<RequestTimeoutException>()));
  });
}
