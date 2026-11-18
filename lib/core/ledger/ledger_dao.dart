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

  /// Accounts of [kind] that are not removed, oldest first.
  Future<List<Account>> activeAccounts(AccountKind kind) => _activeAccounts(kind).get();

  /// Accounts of [kind] that are not removed, oldest first. Ties (added in
  /// the same millisecond) keep the order they were added in (SQLite's rowid).
  SimpleSelectStatement<$AccountsTable, Account> _activeAccounts(AccountKind kind) => select(accounts)
    ..where((a) => a.kind.equals(kind.db) & a.removedAt.isNull())
    ..orderBy([(a) => OrderingTerm.asc(a.createdAt), (_) => OrderingTerm.asc(const CustomExpression<int>('rowid'))]);

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

  /// The total of [accountId]'s postings in transactions that are not
  /// deleted. With [after] (a starting point: an opening balance or a cash
  /// count), only what is dated after it counts, plus anything at the same
  /// moment created from [createdFrom] on, other than [excluding] (the
  /// opening balance itself).
  Future<int> accountTotal(String accountId, {int? after, int? createdFrom, String? excluding}) async {
    final total = postings.amountPaise.sum();
    final query =
        selectOnly(postings)
            .join([innerJoin(ledgerTransactions, ledgerTransactions.id.equalsExp(postings.transactionId))])
          ..addColumns([total])
          ..where(postings.accountId.equals(accountId) & ledgerTransactions.deletedAt.isNull());
    if (after != null) {
      var sameMoment =
          ledgerTransactions.occurredAt.equals(after) & ledgerTransactions.createdAt.isBiggerOrEqualValue(createdFrom!);
      if (excluding != null) sameMoment = sameMoment & ledgerTransactions.id.equals(excluding).not();
      query.where(ledgerTransactions.occurredAt.isBiggerThanValue(after) | sameMoment);
    }
    return (await query.map((row) => row.read(total)).getSingle()) ?? 0;
  }

  /// The latest Update count of [accountId] (Cash in hand) that is not
  /// deleted.
  Future<BalanceCheckpoint?> latestCount(String accountId) =>
      (select(balanceCheckpoints)
            ..where(
              (c) => c.accountId.equals(accountId) & c.source.equals(CheckpointSource.count) & c.deletedAt.isNull(),
            )
            ..orderBy([(c) => OrderingTerm.desc(c.asOf), (c) => OrderingTerm.desc(c.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Marks verified balances of [accountIds] dated after [occurredAt] as
  /// needing a recheck, because something before them changed.
  Future<void> markChecksStale(Iterable<String> accountIds, int occurredAt) =>
      (update(balanceCheckpoints)
            ..where((c) => c.accountId.isIn(accountIds) & c.asOf.isBiggerThanValue(occurredAt) & c.deletedAt.isNull()))
          .write(const BalanceCheckpointsCompanion(needsRecheck: Value(true)));

  /// Banks or cards of [kind] that are not removed, oldest first, as they
  /// change.
  Stream<List<Account>> watchActiveAccounts(AccountKind kind) => _activeAccounts(kind).watch();

  /// Categories that are not removed, in their sheet order, with their
  /// colour and icon.
  Stream<List<(Account, Category)>> watchActiveCategories() {
    final query = select(accounts).join([innerJoin(categories, categories.accountId.equalsExp(accounts.id))])
      ..where(accounts.removedAt.isNull())
      ..orderBy([OrderingTerm.asc(categories.sortOrder)]);
    return query.watch().map((rows) => [for (final row in rows) (row.readTable(accounts), row.readTable(categories))]);
  }

  /// Emits once now and again after every change to the ledger, so a reader
  /// built from several queries stays current.
  Stream<void> watchLedgerChanges() => customSelect(
    'SELECT 1',
    readsFrom: {accounts, ledgerTransactions, postings, balanceCheckpoints},
  ).watch().map((_) {});

  /// What each funding account spent on expenses dated from [fromDate] up to
  /// [toDate] (local days, YYYY-MM-DD, end excluded), less the live refunds
  /// of those expenses: account id → paise. Refunds count in the purchase's
  /// month (the default reporting mode, 17 Nov 2026).
  Future<Map<String, int>> spendingByFunding(String fromDate, String toDate) async {
    final rows = await customSelect(
      '''
      SELECT f.account_id AS account_id,
             SUM(-f.amount_paise) AS spent,
             SUM(COALESCE((
               SELECT SUM(rp.amount_paise)
               FROM ledger_transactions r
               JOIN postings rp ON rp.transaction_id = r.id
               JOIN accounts ra ON ra.id = rp.account_id
               WHERE r.refund_of = t.id AND r.kind = 'refund' AND r.deleted_at IS NULL
                 AND ra.kind IN ('bank', 'credit_card', 'cash')
             ), 0)) AS refunded
      FROM ledger_transactions t
      JOIN postings f ON f.transaction_id = t.id
      WHERE t.kind = 'expense' AND t.deleted_at IS NULL AND f.amount_paise < 0
        AND t.local_date >= ? AND t.local_date < ?
      GROUP BY f.account_id
      ''',
      variables: [Variable.withString(fromDate), Variable.withString(toDate)],
      readsFrom: {ledgerTransactions, postings, accounts},
    ).get();
    return {for (final row in rows) row.read<String>('account_id'): row.read<int>('spent') - row.read<int>('refunded')};
  }

  /// What each category spent on expenses dated from [fromDate] up to
  /// [toDate] (local days, YYYY-MM-DD, end excluded), less the live refunds
  /// of those expenses: category id → paise. Like [spendingByFunding],
  /// refunds count in the purchase's month.
  Future<Map<String, int>> categorySpending(String fromDate, String toDate) async {
    final rows = await customSelect(
      '''
      SELECT c.account_id AS account_id,
             SUM(c.amount_paise) AS spent,
             SUM(COALESCE((
               SELECT SUM(-rp.amount_paise)
               FROM ledger_transactions r
               JOIN postings rp ON rp.transaction_id = r.id
               WHERE r.refund_of = t.id AND r.kind = 'refund' AND r.deleted_at IS NULL
                 AND rp.account_id = c.account_id
             ), 0)) AS refunded
      FROM ledger_transactions t
      JOIN postings c ON c.transaction_id = t.id
      JOIN accounts a ON a.id = c.account_id
      WHERE t.kind = 'expense' AND t.deleted_at IS NULL AND a.kind = 'category'
        AND t.local_date >= ? AND t.local_date < ?
      GROUP BY c.account_id
      ''',
      variables: [Variable.withString(fromDate), Variable.withString(toDate)],
      readsFrom: {ledgerTransactions, postings, accounts},
    ).get();
    return {for (final row in rows) row.read<String>('account_id'): row.read<int>('spent') - row.read<int>('refunded')};
  }

  /// The rows behind a spending report: live expenses dated from
  /// [fromDate] up to [toDate] (local days, YYYY-MM-DD, end excluded) with
  /// their live refunds so far, and live refunds that came back in those
  /// days with their purchase's day. Newest first.
  Future<List<SpendingEntry>> spendingEntries(String fromDate, String toDate) async {
    // The account a purchase was paid from, or a refund came back to: its
    // posting on a bank account, card or Cash in hand.
    const money = "a.kind IN ('bank', 'credit_card', 'cash')";
    final rows = await customSelect(
      '''
      SELECT t.id, t.kind, t.occurred_at, t.local_date, t.payment_method, t.channel, t.merchant, t.note,
             t.refund_of, o.local_date AS original_date,
             (SELECT p.account_id FROM postings p JOIN accounts a ON a.id = p.account_id
               WHERE p.transaction_id = t.id AND a.kind = 'category') AS category_id,
             (SELECT p.account_id FROM postings p JOIN accounts a ON a.id = p.account_id
               WHERE p.transaction_id = t.id AND $money) AS account_id,
             (SELECT a.name FROM postings p JOIN accounts a ON a.id = p.account_id
               WHERE p.transaction_id = t.id AND $money) AS account_name,
             (SELECT ABS(p.amount_paise) FROM postings p JOIN accounts a ON a.id = p.account_id
               WHERE p.transaction_id = t.id AND $money) AS amount,
             CASE WHEN t.kind = 'expense' THEN COALESCE((
               SELECT SUM(rp.amount_paise)
               FROM ledger_transactions r
               JOIN postings rp ON rp.transaction_id = r.id
               JOIN accounts a ON a.id = rp.account_id
               WHERE r.refund_of = t.id AND r.kind = 'refund' AND r.deleted_at IS NULL AND $money
             ), 0) ELSE 0 END AS refunded
      FROM ledger_transactions t
      LEFT JOIN ledger_transactions o ON o.id = t.refund_of
      WHERE t.kind IN ('expense', 'refund') AND t.deleted_at IS NULL
        AND t.local_date >= ? AND t.local_date < ?
      ORDER BY t.occurred_at DESC, t.created_at DESC
      ''',
      variables: [Variable.withString(fromDate), Variable.withString(toDate)],
      readsFrom: {ledgerTransactions, postings, accounts},
    ).get();
    return [
      for (final row in rows)
        SpendingEntry(
          id: row.read<String>('id'),
          isRefund: row.read<String>('kind') == TransactionKind.refund.db,
          occurredAt: DateTime.fromMillisecondsSinceEpoch(row.read<int>('occurred_at'), isUtc: true),
          localDate: row.read<String>('local_date'),
          amountPaise: row.read<int>('amount'),
          method: PaymentMethod.fromDb(row.read<String>('payment_method')).shownAs,
          accountId: row.read<String>('account_id'),
          accountName: row.read<String>('account_name'),
          categoryId: row.read<String>('category_id'),
          channel: row.readNullable<String>('channel'),
          merchant: row.readNullable<String>('merchant'),
          note: row.readNullable<String>('note'),
          refundedPaise: row.read<int>('refunded'),
          originalId: row.readNullable<String>('refund_of'),
          originalDate: row.readNullable<String>('original_date'),
        ),
    ];
  }

  /// Live transactions (expenses and refunds) with a posting on any of
  /// [accountIds], oldest first.
  Future<List<LedgerTransaction>> liveTransactionsOn(Iterable<String> accountIds) {
    final query =
        select(ledgerTransactions).join([innerJoin(postings, postings.transactionId.equalsExp(ledgerTransactions.id))])
          ..where(postings.accountId.isIn(accountIds) & ledgerTransactions.deletedAt.isNull())
          ..orderBy([OrderingTerm.asc(ledgerTransactions.occurredAt)]);
    return query.map((row) => row.readTable(ledgerTransactions)).get();
  }

  /// The highest sort order among categories, or -1 when there are none.
  Future<int> lastCategoryOrder() async {
    final max = categories.sortOrder.max();
    final row = await (selectOnly(categories)..addColumns([max])).getSingle();
    return row.read(max) ?? -1;
  }

  /// The latest live transfer into [accountId], such as an ATM withdrawal
  /// into Cash in hand: (paise, UTC milliseconds).
  Future<(int, int)?> lastTransferInto(String accountId) async {
    final query =
        select(ledgerTransactions).join([innerJoin(postings, postings.transactionId.equalsExp(ledgerTransactions.id))])
          ..where(
            ledgerTransactions.kind.equals(TransactionKind.transfer.db) &
                ledgerTransactions.deletedAt.isNull() &
                postings.accountId.equals(accountId) &
                postings.amountPaise.isBiggerThanValue(0),
          )
          ..orderBy([OrderingTerm.desc(ledgerTransactions.occurredAt)])
          ..limit(1);
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (row.readTable(postings).amountPaise, row.readTable(ledgerTransactions).occurredAt);
  }

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
