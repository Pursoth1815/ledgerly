import 'package:dio/dio.dart';
import '../../../config/environment.dart';

class DioClient {
  DioClient._();

  static Dio create() {
    return Dio(
      BaseOptions(
        baseUrl: Environment.apiBaseUrl,
        connectTimeout: Environment.connectTimeout,
        receiveTimeout: Environment.receiveTimeout,
      ),
    );
  }
}
