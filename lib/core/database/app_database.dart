import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.steps.dart';
import 'tables/background.dart';
import 'tables/ledger.dart';
import 'tables/settings.dart';

part 'app_database.g.dart';

/// The app's single database (ADR 0004).
///
/// One file, one schema version for the whole app. Each owner (an engine or a
/// feature) adds its tables in the phase that builds it, grouped in
/// `core/database/tables/`, and reads and writes them only through its own
/// DAO. Migrations are generated and tested with `drift_dev make-migrations`
/// (ADR 0005); never edit a released step.
@DriftDatabase(
  tables: [
    JobCheckpoints,
    AppSettings,
    Accounts,
    Categories,
    LedgerTransactions,
    Postings,
    TransactionRevisions,
    BalanceCheckpoints,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: stepByStep(
      // Phase 0B: background job checkpoints (ADR 0013).
      from1To2: (migrator, schema) async {
        await migrator.createTable(schema.jobCheckpoints);
      },
      // Phase 1: app settings, starting with the theme.
      from2To3: (migrator, schema) async {
        await migrator.createTable(schema.appSettings);
      },
      // Phase 2: the double-entry ledger (ADR 0006).
      from3To4: (migrator, schema) async {
        await migrator.createTable(schema.accounts);
        await migrator.createTable(schema.categories);
        await migrator.createTable(schema.ledgerTransactions);
        await migrator.createTable(schema.postings);
        await migrator.createTable(schema.transactionRevisions);
        await migrator.createTable(schema.balanceCheckpoints);
      },
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

/// The open database. Opened in `bootstrap()` before the first frame and
/// injected by overriding this provider.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) => throw UnimplementedError('appDatabaseProvider is overridden in bootstrap');
