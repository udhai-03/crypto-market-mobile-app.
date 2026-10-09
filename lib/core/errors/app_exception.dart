import 'package:crypto_market_mobile/core/constants/app_strings.dart';

/// Application-level failures that are safe to show to the user.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class NoConnectionException extends AppException {
  const NoConnectionException() : super(AppStrings.noConnectionError);
}

final class RequestTimeoutException extends AppException {
  const RequestTimeoutException() : super(AppStrings.timeoutError);
}

final class ServerException extends AppException {
  const ServerException(this.statusCode) : super(AppStrings.serverError);

  final int? statusCode;
}

final class InvalidResponseException extends AppException {
  const InvalidResponseException() : super(AppStrings.invalidResponseError);
}

/// Local storage could not be read or written.
final class StorageException extends AppException {
  const StorageException(super.message);
}

final class UnexpectedException extends AppException {
  const UnexpectedException() : super(AppStrings.unexpectedError);
}
