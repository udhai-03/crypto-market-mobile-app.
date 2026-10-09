import 'package:dio/dio.dart';

import 'package:crypto_market_mobile/core/errors/app_exception.dart';

AppException mapDioException(DioException exception) {
  return switch (exception.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.transformTimeout => const RequestTimeoutException(),
    DioExceptionType.connectionError => const NoConnectionException(),
    DioExceptionType.badResponse => ServerException(
      exception.response?.statusCode,
    ),
    DioExceptionType.unknown when exception.error is FormatException =>
      const InvalidResponseException(),
    DioExceptionType.badCertificate ||
    DioExceptionType.cancel ||
    DioExceptionType.unknown => const UnexpectedException(),
  };
}
