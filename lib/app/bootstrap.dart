import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

import '../core/background/job_runner.dart';
import '../core/database/app_database.dart';
import '../core/database/database_opener.dart';
import '../core/errors/app_exception.dart';
import '../core/ledger/ledger_engine.dart';
import '../core/logging/logging_setup.dart';
import '../core/platform/platform_api.g.dart';
import '../core/security/database_key_store.dart';
import '../core/settings/theme_setting.dart';
import '../design_system/font_licenses.dart';
import 'app.dart';
import 'background/app_jobs.dart';
import 'config/app_config.dart';
import 'startup_failure_app.dart';

final _log = Logger('app.bootstrap');

/// Starts the app (ADR 0001): logging, flavour config, the encrypted
/// database, then the first frame. If the data cannot be opened, a failure
/// screen is shown and nothing is touched.
///
/// On Android the app first becomes the only database writer (ADR 0013): a
/// background job that is writing stops at its next checkpoint, and then
/// continues in this engine.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureLogging();
  final config = AppConfig.fromFlavor(appFlavor);
  registerFontLicenses();
  // iOS has no background engine yet (Not Yet Verified).
  final background = defaultTargetPlatform == TargetPlatform.android ? BackgroundHostApi() : null;
  await background?.acquireWriter();

  final AppDatabase database;
  try {
    database = await openAppDatabase(
      keys: DatabaseKeyStore(KeyStoreApi()),
      directory: await getApplicationSupportDirectory(),
    );
  } on AppException catch (error) {
    _log.severe('startup_failed code=${error.code}');
    await background?.engineFailed(error.code);
    runApp(StartupFailureApp(error: error));
    return;
  }
  // Cash in hand, the bookkeeping accounts and the default categories.
  try {
    await LedgerEngine(database).ensureDefaults();
  } on AppException catch (error) {
    _log.severe('startup_failed code=${error.code}');
    await background?.engineFailed(error.code);
    runApp(StartupFailureApp(error: error));
    return;
  }
  if (background != null) {
    BackgroundJobApi.setUp(JobRunner(appJobs(database)));
    await background.engineReady();
  }
  // Read before the first frame, so the app never flashes the wrong theme.
  final themeMode = await ThemeSettingStore(database).load();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        appDatabaseProvider.overrideWithValue(database),
        initialThemeModeProvider.overrideWithValue(themeMode),
      ],
      child: const LoopdApp(),
    ),
  );
}
