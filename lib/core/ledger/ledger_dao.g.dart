// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_dao.dart';

// ignore_for_file: type=lint
mixin _$LedgerDaoMixin on DatabaseAccessor<AppDatabase> {
  $AccountsTable get accounts => attachedDatabase.accounts;
  $CategoriesTable get categories => attachedDatabase.categories;
  $LedgerTransactionsTable get ledgerTransactions => attachedDatabase.ledgerTransactions;
  $PostingsTable get postings => attachedDatabase.postings;
  $TransactionRevisionsTable get transactionRevisions => attachedDatabase.transactionRevisions;
  $BalanceCheckpointsTable get balanceCheckpoints => attachedDatabase.balanceCheckpoints;
  LedgerDaoManager get managers => LedgerDaoManager(this);
}

class LedgerDaoManager {
  final _$LedgerDaoMixin _db;
  LedgerDaoManager(this._db);
  $$AccountsTableTableManager get accounts => $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$CategoriesTableTableManager get categories => $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$LedgerTransactionsTableTableManager get ledgerTransactions =>
      $$LedgerTransactionsTableTableManager(_db.attachedDatabase, _db.ledgerTransactions);
  $$PostingsTableTableManager get postings => $$PostingsTableTableManager(_db.attachedDatabase, _db.postings);
  $$TransactionRevisionsTableTableManager get transactionRevisions =>
      $$TransactionRevisionsTableTableManager(_db.attachedDatabase, _db.transactionRevisions);
  $$BalanceCheckpointsTableTableManager get balanceCheckpoints =>
      $$BalanceCheckpointsTableTableManager(_db.attachedDatabase, _db.balanceCheckpoints);
}
