import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import '../errors/app_exception.dart';
import '../platform/platform_api.g.dart';

final _log = Logger('core.security');

/// Reads the database key that Kotlin keeps wrapped by the Android Keystore
/// (ADR 0009). The key exists in Dart memory only while the database is open.
class DatabaseKeyStore {
  DatabaseKeyStore(this._api);

  static const keyLength = 32;

  final KeyStoreApi _api;

  /// The 32-byte database key. Creates one only when [createIfMissing] is
  /// true, which the caller sets only when no database file exists yet.
  ///
  /// Throws [KeyAccessException]; it never invents a replacement key.
  Future<Uint8List> databaseKey({required bool createIfMissing}) async {
    final Uint8List key;
    try {
      key = await _api.databaseKey(createIfMissing);
    } on PlatformException catch (error) {
      _log.severe('key_failed code=${error.code}');
      throw KeyAccessException(KeyAccessFailure.fromCode(error.code));
    }
    if (key.length != keyLength) {
      _log.severe('key_rejected reason=wrong_length');
      throw const KeyAccessException(KeyAccessFailure.keyCorrupt);
    }
    // Proof the key crossed from Kotlin to Dart. The length only, never bytes.
    _log.info('key_received from=kotlin length=${key.length}');
    return key;
  }
}
