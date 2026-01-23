import 'package:dio/dio.dart';
import 'package:ledgerly/core/utils/logger.dart';

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, handler) {
    AppLogger.d(
      '➡️ ${options.method} ${options.uri}',
      tag: 'NETWORK',
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, handler) {
    AppLogger.d(
      '✅ ${response.statusCode} ${response.requestOptions.uri}',
      tag: 'NETWORK',
    );
    handler.next(response);
  }
}
