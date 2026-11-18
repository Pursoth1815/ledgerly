import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/background/job_runner.dart';
import '../../core/database/database_opener.dart';
import '../../core/errors/app_exception.dart';
import '../../core/logging/logging_setup.dart';
import '../../core/platform/platform_api.g.dart';
import '../../core/security/database_key_store.dart';
import 'app_jobs.dart';

final _log = Logger('app.background');

/// Starts the headless engine (ADR 0013): opens the database and tells
/// Kotlin it can run jobs. Kotlin starts this engine only while it holds the
/// single-writer gate, and destroys it when its jobs end.
///
/// It never creates a database: if the app has not been opened yet, there is
/// nothing to work on.
Future<void> backgroundBootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  configureLogging();
  final host = BackgroundHostApi();

  final directory = await getApplicationSupportDirectory();
  if (!File(p.join(directory.path, databaseFileName)).existsSync()) {
    _log.warning('background_not_started reason=no_database');
    await host.engineFailed('database.missing');
    return;
  }
  try {
    final database = await openAppDatabase(keys: DatabaseKeyStore(KeyStoreApi()), directory: directory);
    BackgroundJobApi.setUp(JobRunner(appJobs(database)));
  } on AppException catch (error) {
    _log.severe('background_failed code=${error.code}');
    await host.engineFailed(error.code);
    return;
  }
  await host.engineReady();
}
