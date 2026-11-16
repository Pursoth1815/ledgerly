import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:loopd/core/errors/app_exception.dart';
import 'package:loopd/core/platform/platform_api.g.dart';
import 'package:loopd/core/security/database_key_store.dart';

void main() {
  test('returns a 32-byte key and passes createIfMissing through', () async {
    final api = _Api(result: Uint8List(32));
    final key = await DatabaseKeyStore(api).databaseKey(createIfMissing: false);

    expect(key, hasLength(32));
    expect(api.lastCreateIfMissing, isFalse);
  });

  test('logs that the key arrived from Kotlin, with its length but never its bytes', () async {
    final messages = <String>[];
    final subscription = Logger.root.onRecord.listen((record) => messages.add(record.message));
    addTearDown(subscription.cancel);

    await DatabaseKeyStore(_Api(result: Uint8List.fromList(List.filled(32, 0xAB)))).databaseKey(createIfMissing: true);

    expect(messages, ['key_received from=kotlin length=32']);
    expect(messages.join(), isNot(contains('171')));
  });

  test('a key of the wrong length is rejected as corrupt', () {
    expect(
      DatabaseKeyStore(_Api(result: Uint8List(16))).databaseKey(createIfMissing: true),
      throwsA(_failure(KeyAccessFailure.keyCorrupt)),
    );
  });

  for (final failure in KeyAccessFailure.values) {
    test('platform code ${failure.code} maps to $failure', () {
      expect(
        DatabaseKeyStore(_Api(errorCode: failure.code)).databaseKey(createIfMissing: true),
        throwsA(_failure(failure)),
      );
    });
  }

  test('an unknown platform code is never treated as success', () {
    expect(
      DatabaseKeyStore(_Api(errorCode: 'something_new')).databaseKey(createIfMissing: true),
      throwsA(_failure(KeyAccessFailure.keystoreUnavailable)),
    );
  });
}

Matcher _failure(KeyAccessFailure failure) => isA<KeyAccessException>().having((e) => e.failure, 'failure', failure);

class _Api extends KeyStoreApi {
  _Api({this.result, this.errorCode});

  final Uint8List? result;
  final String? errorCode;
  bool? lastCreateIfMissing;

  @override
  Future<Uint8List> databaseKey(bool createIfMissing) async {
    lastCreateIfMissing = createIfMissing;
    final code = errorCode;
    if (code != null) throw PlatformException(code: code);
    return result!;
  }
}
