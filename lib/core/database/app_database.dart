import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_database.g.dart';

/// The app's single database (ADR 0004).
///
/// One file, one schema version for the whole app. Each owner (an engine or a
/// feature) adds its tables in the phase that builds it, grouped in
/// `core/database/tables/`, and reads and writes them only through its own
/// DAO. Migrations are generated and tested with `drift_dev make-migrations`
/// (ADR 0005); never edit a released step.
@DriftDatabase(tables: [])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// The open database. Opened in `bootstrap()` before the first frame and
/// injected by overriding this provider.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) => throw UnimplementedError('appDatabaseProvider is overridden in bootstrap');
