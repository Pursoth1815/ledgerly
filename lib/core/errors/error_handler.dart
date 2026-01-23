import 'package:dio/dio.dart';
import 'app_exception.dart';

class ErrorHandler {
  static AppException handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
          return AppException.timeout();

        case DioExceptionType.connectionError:
          return AppException.network();

        case DioExceptionType.badResponse:
          return AppException.server(
            error.response?.data['message'] ?? 'Server error',
          );

        default:
          return AppException.unknown();
      }
    }

    return AppException.unknown();
  }
}
