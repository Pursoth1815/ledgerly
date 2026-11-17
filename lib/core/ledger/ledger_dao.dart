import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables/ledger.dart';
import 'ledger_types.dart';

part 'ledger_dao.g.dart';

/// Reads and writes the ledger tables. Used only inside `core/ledger`
/// (architecture rule 4); everything else goes through [LedgerEngine].
@DriftAccessor(tables: [Accounts, Categories, LedgerTransactions, Postings, TransactionRevisions, BalanceCheckpoints])
class LedgerDao extends DatabaseAccessor<AppDatabase> with _$LedgerDaoMixin {
  LedgerDao(super.attachedDatabase);

  /// One account, removed or not.
  Future<Account?> getAccount(String id) => (select(accounts)..where((a) => a.id.equals(id))).getSingleOrNull();

  /// The kind of each account in [ids] (bank, card, category…).
  Future<Map<String, AccountKind>> accountKinds(Iterable<String> ids) async {
    final rows = await (select(accounts)..where((a) => a.id.isIn(ids))).get();
    return {for (final row in rows) row.id: AccountKind.fromDb(row.kind)};
  }

  /// Accounts of [kind] that are not removed.
  Future<List<Account>> activeAccounts(AccountKind kind) =>
      (select(accounts)..where((a) => a.kind.equals(kind.db) & a.removedAt.isNull())).get();

  /// One transaction, deleted or not.
  Future<LedgerTransaction?> getTransaction(String id) =>
      (select(ledgerTransactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// A transaction's postings: account id → paise (+ in, − out).
  Future<Map<String, int>> getPostings(String transactionId) async {
    final rows = await (select(postings)..where((p) => p.transactionId.equals(transactionId))).get();
    return {for (final row in rows) row.accountId: row.amountPaise};
  }

  /// Replaces a transaction's postings with [amounts].
  Future<void> savePostings(String transactionId, Map<String, int> amounts, String Function() newId) async {
    await (delete(postings)..where((p) => p.transactionId.equals(transactionId))).go();
    await batch((batch) {
      batch.insertAll(postings, [
        for (final MapEntry(key: account, value: paise) in amounts.entries)
          PostingsCompanion.insert(id: newId(), transactionId: transactionId, accountId: account, amountPaise: paise),
      ]);
    });
  }

  /// The saved snapshot of one revision, used by undo.
  Future<TransactionRevision?> getRevision(String transactionId, int revision) => (select(
    transactionRevisions,
  )..where((r) => r.transactionId.equals(transactionId) & r.revision.equals(revision))).getSingleOrNull();

  /// Refunds of [originalId] that are not deleted, except [excluding].
  Future<List<LedgerTransaction>> activeRefunds(String originalId, {String? excluding}) {
    final query = select(ledgerTransactions)
      ..where((t) => t.refundOf.equals(originalId) & t.deletedAt.isNull() & t.kind.equals(TransactionKind.refund.db));
    if (excluding != null) query.where((t) => t.id.equals(excluding).not());
    return query.get();
  }

  /// The latest opening balance of [accountId] that is not deleted.
  Future<LedgerTransaction?> getOpeningBalance(String accountId) {
    final query =
        select(ledgerTransactions).join([innerJoin(postings, postings.transactionId.equalsExp(ledgerTransactions.id))])
          ..where(
            ledgerTransactions.kind.equals(TransactionKind.openingBalance.db) &
                ledgerTransactions.deletedAt.isNull() &
                postings.accountId.equals(accountId),
          )
          ..orderBy([OrderingTerm.desc(ledgerTransactions.occurredAt)])
          ..limit(1);
    return query.map((row) => row.readTable(ledgerTransactions)).getSingleOrNull();
  }

  /// The total of [accountId]'s postings in transactions that are not deleted. With [after]
  /// (an opening balance), only what is dated after it counts, plus anything
  /// at the same moment created after it ([openingId], [openingCreatedAt]).
  Future<int> accountTotal(String accountId, {int? after, String? openingId, int? openingCreatedAt}) async {
    final total = postings.amountPaise.sum();
    final query =
        selectOnly(postings)
            .join([innerJoin(ledgerTransactions, ledgerTransactions.id.equalsExp(postings.transactionId))])
          ..addColumns([total])
          ..where(postings.accountId.equals(accountId) & ledgerTransactions.deletedAt.isNull());
    if (after != null) {
      query.where(
        ledgerTransactions.occurredAt.isBiggerThanValue(after) |
            (ledgerTransactions.occurredAt.equals(after) &
                ledgerTransactions.id.equals(openingId!).not() &
                ledgerTransactions.createdAt.isBiggerOrEqualValue(openingCreatedAt!)),
      );
    }
    return (await query.map((row) => row.read(total)).getSingle()) ?? 0;
  }

  /// Marks verified balances of [accountIds] dated after [occurredAt] as
  /// needing a recheck, because something before them changed.
  Future<void> markChecksStale(Iterable<String> accountIds, int occurredAt) =>
      (update(balanceCheckpoints)
            ..where((c) => c.accountId.isIn(accountIds) & c.asOf.isBiggerThanValue(occurredAt) & c.deletedAt.isNull()))
          .write(const BalanceCheckpointsCompanion(needsRecheck: Value(true)));

  /// Every transaction that is not deleted (for the health check).
  Future<List<LedgerTransaction>> activeTransactions() =>
      (select(ledgerTransactions)..where((t) => t.deletedAt.isNull())).get();

  /// Every posting, grouped by transaction (for the health check).
  Future<Map<String, Map<String, int>>> allPostings() async {
    final out = <String, Map<String, int>>{};
    for (final row in await select(postings).get()) {
      (out[row.transactionId] ??= {})[row.accountId] = row.amountPaise;
    }
    return out;
  }

  /// The kind of every account (for the health check).
  Future<Map<String, AccountKind>> allAccountKinds() async => {
    for (final row in await select(accounts).get()) row.id: AccountKind.fromDb(row.kind),
  };
}
