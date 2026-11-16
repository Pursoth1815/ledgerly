import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

import '../core/database/app_database.dart';
import '../core/database/database_opener.dart';
import '../core/errors/app_exception.dart';
import '../core/logging/logging_setup.dart';
import '../core/platform/platform_api.g.dart';
import '../core/security/database_key_store.dart';
import 'app.dart';
import 'config/app_config.dart';
import 'startup_failure_app.dart';

final _log = Logger('app.bootstrap');

/// Starts the app (ADR 0001): logging, flavour config, the encrypted
/// database, then the first frame. If the data cannot be opened, a failure
/// screen is shown and nothing is touched.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureLogging(debugOutput: kDebugMode);
  final config = AppConfig.fromFlavor(appFlavor);

  final AppDatabase database;
  try {
    database = await openAppDatabase(
      keys: DatabaseKeyStore(KeyStoreApi()),
      directory: await getApplicationSupportDirectory(),
    );
  } on AppException catch (error) {
    _log.severe('startup_failed code=${error.code}');
    runApp(StartupFailureApp(error: error));
    return;
  }

  runApp(
    ProviderScope(
      overrides: [appConfigProvider.overrideWithValue(config), appDatabaseProvider.overrideWithValue(database)],
      child: const LoopdApp(),
    ),
  );
}
