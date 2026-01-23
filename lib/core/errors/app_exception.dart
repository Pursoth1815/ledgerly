class AppException implements Exception {
  final String message;
  final AppExceptionType type;

  AppException(this.message, this.type);

  factory AppException.network() =>
      AppException('No internet connection', AppExceptionType.network);

  factory AppException.timeout() =>
      AppException('Request timed out', AppExceptionType.timeout);

  factory AppException.server(String message) =>
      AppException(message, AppExceptionType.server);

  factory AppException.unknown() =>
      AppException('Something went wrong', AppExceptionType.unknown);
}

enum AppExceptionType {
  network,
  timeout,
  server,
  unknown,
}
