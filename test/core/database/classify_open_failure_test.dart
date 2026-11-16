import 'package:flutter_test/flutter_test.dart';
import 'package:loopd/core/database/database_opener.dart';
import 'package:loopd/core/database/encrypted_executor.dart';
import 'package:loopd/core/errors/app_exception.dart';

void main() {
  DatabaseOpenFailure classify(Object error) => classifyOpenFailure(error).failure;

  test('the SQLCipher marker means encryption is unavailable', () {
    expect(classify(StateError(cipherUnavailableMarker)), DatabaseOpenFailure.encryptionUnavailable);
  });

  test("SQLite's not-a-database message means the key does not match", () {
    expect(classify(Exception('SqliteException(26): file is not a database')), DatabaseOpenFailure.keyMismatch);
  });

  test('anything else is a general open failure', () {
    expect(classify(Exception('disk I/O error')), DatabaseOpenFailure.openFailed);
  });

  test('an existing DatabaseOpenException passes through', () {
    const error = DatabaseOpenException(DatabaseOpenFailure.keyMismatch);
    expect(classifyOpenFailure(error), same(error));
  });
}
