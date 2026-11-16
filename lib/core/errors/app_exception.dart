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
