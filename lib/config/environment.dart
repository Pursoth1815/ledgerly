import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  Environment._();

  static String get flavor => dotenv.env['FLAVOR'] ?? 'prod';

  static String get apiBaseUrl {
    final url = dotenv.env['API_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('API_URL is not set');
    }
    return url;
  }

  static Duration get connectTimeout => Duration(seconds: int.parse(dotenv.env['CONNECT_TIMEOUT'] ?? '10'));

  static Duration get receiveTimeout => Duration(seconds: int.parse(dotenv.env['RECEIVE_TIMEOUT'] ?? '10'));

  static bool get enableNetworkLogs => dotenv.env['ENABLE_NETWORK_LOGS'] == 'true';

  static bool get isProd => flavor == 'prod';

  static bool get isDev => flavor == 'dev';

  static void validate() {
    apiBaseUrl;
  }
}
