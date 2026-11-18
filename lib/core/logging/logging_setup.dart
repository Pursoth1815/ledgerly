import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'log_redaction.dart';

/// Configures `package:logging` for the whole app (ADR 0014).
///
/// Code logs events with safe fields only, for example
/// `Logger('core.database').info('opened schema=1')`. Errors are written as
/// their type, never their message, because messages can carry data.
/// Lines go to the debug console only in debug builds ([kDebugMode]); the
/// on-phone log file and its export arrive with the Export logs screen.
void configureLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    if (kDebugMode) debugPrint(formatLogRecord(record));
  });
}

/// One redacted line for [record].
String formatLogRecord(LogRecord record) {
  final error = record.error == null ? '' : ' | ${record.error.runtimeType}';
  return redactSensitive('${record.level.name} ${record.loggerName}: ${record.message}$error');
}
