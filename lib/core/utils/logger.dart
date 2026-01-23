import 'dart:developer';

class AppLogger {
  static bool _enabled = true;

  static void init({required bool enableLogs}) {
    _enabled = enableLogs;
  }

  static void d(String message, {String tag = 'APP'}) {
    if (_enabled) {
      log(message, name: tag);
    }
  }

  static void e(String message,
      {String tag = 'APP', StackTrace? stackTrace}) {
    if (_enabled) {
      log(message, name: tag, error: message, stackTrace: stackTrace);
    }
  }
}
