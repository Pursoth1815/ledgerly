/// The exceptions the app raises on purpose (ADR 0014).
///
/// Raw exceptions (SQLite, platform channels, I/O) are converted into one of
/// these at the data and platform edges. Screens turn them into words through a
/// single mapping. New cases are added here when the phase that needs them is
/// built.
library;

sealed class AppException implements Exception {
  const AppException();

  /// A stable, data-free code for logs and support, for example `key.key_missing`.
  String get code;

  @override
  String toString() => '$runtimeType($code)';
}

/// Why the database key could not be read. The `code` values match the Pigeon
/// contract in `pigeons/platform_api.dart`.
enum KeyAccessFailure {
  keyMissing('key_missing'),
  keyCorrupt('key_corrupt'),
  keystoreUnavailable('keystore_unavailable');

  const KeyAccessFailure(this.code);

  final String code;

  /// Unknown codes are treated as an unavailable Keystore, never as success.
  static KeyAccessFailure fromCode(String code) =>
      values.firstWhere((failure) => failure.code == code, orElse: () => keystoreUnavailable);
}

final class KeyAccessException extends AppException {
  const KeyAccessException(this.failure);

  final KeyAccessFailure failure;

  @override
  String get code => 'key.${failure.code}';
}

/// Why the encrypted database could not be opened.
enum DatabaseOpenFailure {
  /// The SQLite library in the app is not SQLCipher, so nothing is opened.
  encryptionUnavailable('encryption_unavailable'),

  /// The key does not open this database file.
  keyMismatch('key_mismatch'),

  /// Any other failure while opening or migrating.
  openFailed('open_failed');

  const DatabaseOpenFailure(this.code);

  final String code;
}

final class DatabaseOpenException extends AppException {
  const DatabaseOpenException(this.failure);

  final DatabaseOpenFailure failure;

  @override
  String get code => 'database.${failure.code}';
}

/// Why the ledger refused a change (ADR 0006). Nothing is written when one
/// of these is thrown.
enum LedgerFailure {
  /// The postings do not sum to zero.
  unbalanced('unbalanced'),

  /// A transaction needs at least two postings.
  tooFewPostings('too_few_postings'),

  /// An amount must be a positive number of paise.
  invalidAmount('invalid_amount'),

  /// The postings do not have this kind's fixed shape.
  wrongShape('wrong_shape'),

  /// The payment method does not fit the funding account, or is missing or
  /// not allowed for this kind.
  methodMismatch('method_mismatch'),

  /// A refund must point to a live expense.
  refundWithoutOriginal('refund_without_original'),

  /// Refunds can never add up to more than the original.
  refundExceedsOriginal('refund_exceeds_original'),

  /// A purchase with live refunds is deleted only together with them.
  hasLiveRefunds('has_live_refunds'),

  /// Undo works only while nothing has changed since.
  changedSince('changed_since'),

  /// The transaction or account does not exist.
  notFound('not_found'),

  /// New money cannot be recorded against a removed account.
  accountRemoved('account_removed'),

  /// Built-in accounts, such as Cash in hand, cannot be removed.
  systemAccount('system_account'),

  /// An account or card needs a nickname, a bank and exactly four digits.
  invalidAccount('invalid_account'),

  /// These last four digits are already saved for another bank account, or
  /// another card. The Add sheet checks this as you type; the ledger checks
  /// again on save, so no other path can add a second one.
  duplicateAccount('duplicate_account'),

  /// Loans, repayments and write-offs arrive with lending (Phase 4).
  notBuiltYet('not_built_yet');

  const LedgerFailure(this.code);

  final String code;
}

final class LedgerException extends AppException {
  const LedgerException(this.failure);

  final LedgerFailure failure;

  @override
  String get code => 'ledger.${failure.code}';
}
