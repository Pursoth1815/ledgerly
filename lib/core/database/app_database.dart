import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'app_database.steps.dart';
import 'migrations/unique_category_looks.dart';
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
  int get schemaVersion => 7;

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
      // Phase 2, part 2: the bank name of each account and card.
      from4To5: (migrator, schema) async {
        await migrator.addColumn(schema.accounts, schema.accounts.bankName);
      },
      // Phase 2, part 4: sixteen colours, and no two categories share a
      // colour or an icon. Tidy the rows first, then rebuild the table with
      // the new limits.
      from5To6: (migrator, schema) async {
        final rows = await customSelect('SELECT account_id, colour, icon FROM categories ORDER BY sort_order').get();
        final looks = uniqueCategoryLooks([
          for (final row in rows) (row.read<String>('account_id'), row.read<int>('colour'), row.read<String>('icon')),
        ]);
        // The old table still checks colours 0 to 7 and has no unique keys,
        // so its check is paused for the new colours; the rebuilt table
        // checks them all again as the rows are copied in.
        await customStatement('PRAGMA ignore_check_constraints = ON');
        try {
          for (final (id, colour, icon) in looks) {
            await customUpdate(
              'UPDATE categories SET colour = ?, icon = ? WHERE account_id = ?',
              variables: [Variable.withInt(colour), Variable.withString(icon), Variable.withString(id)],
            );
          }
        } finally {
          await customStatement('PRAGMA ignore_check_constraints = OFF');
        }
        await migrator.alterTable(TableMigration(schema.categories));
      },
      // Phase 2, part 4, review: twenty-five colours, as many as the icons.
      // Misc, the new default, is added by the ledger's defaults on start.
      from6To7: (migrator, schema) async {
        await migrator.alterTable(TableMigration(schema.categories));
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
