import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/check_architecture.dart';

void main() {
  List<String> importProblems(String source, String import) =>
      checkDartImports({source: "import '$import';"}).map((v) => v.message).toList();

  group('Dart imports', () {
    test('core may not depend on features, app or the design system', () {
      expect(importProblems('lib/core/ledger/ledger_engine.dart', 'package:loopd/features/expenses/expenses.dart'), [
        contains('core must not depend on features'),
      ]);
      expect(importProblems('lib/core/ledger/ledger_engine.dart', '../../app/app.dart'), [
        contains('core must not depend on app'),
      ]);
      expect(importProblems('lib/core/ledger/ledger_engine.dart', 'package:loopd/design_system/x.dart'), [
        contains('core must not depend on design_system'),
      ]);
    });

    test('the design system depends on nothing in the app', () {
      expect(importProblems('lib/design_system/components/card.dart', 'package:loopd/core/errors/app_exception.dart'), [
        contains('design_system must not depend on core'),
      ]);
    });

    test('a feature uses only the public file of another feature', () {
      expect(
        importProblems(
          'lib/features/today/presentation/today_screen.dart',
          'package:loopd/features/travel/travel.dart',
        ),
        isEmpty,
      );
      expect(
        importProblems('lib/features/today/presentation/today_screen.dart', '../../travel/data/travel_repository.dart'),
        [contains('import only lib/features/travel/travel.dart')],
      );
    });

    test('a feature may use its own internals and core', () {
      expect(importProblems('lib/features/travel/presentation/x.dart', '../data/travel_repository.dart'), isEmpty);
      expect(
        importProblems('lib/features/travel/data/x.dart', 'package:loopd/core/database/app_database.dart'),
        isEmpty,
      );
    });

    test('features may not depend on app', () {
      expect(importProblems('lib/features/travel/travel.dart', 'package:loopd/app/app.dart'), [
        contains('features must not depend on app'),
      ]);
    });

    test('a DAO is used only by the module that owns it', () {
      expect(importProblems('lib/features/expenses/data/x.dart', 'package:loopd/core/ledger/ledger_dao.dart'), [
        contains('a DAO is used only by the module that owns it (core/ledger)'),
      ]);
      expect(importProblems('lib/core/ledger/ledger_engine.dart', 'ledger_dao.dart'), isEmpty);
    });

    test('packages never import the app', () {
      expect(importProblems('packages/sms_parser/lib/sms_parser.dart', 'package:loopd/core/x.dart'), [
        contains('packages must not import the app'),
      ]);
    });

    test('app may use everything', () {
      expect(importProblems('lib/app/router/app_router.dart', 'package:loopd/features/travel/data/x.dart'), isEmpty);
    });
  });

  group('Kotlin', () {
    test('unencrypted keyset APIs are rejected', () {
      final violations = checkKotlinSources({
        'A.kt': 'val m = AndroidKeysetManager.Builder()',
        'B.kt': 'CleartextKeysetHandle.write(h, w)',
        'C.kt': 'TinkProtoKeysetFormat.serializeKeyset(h, access)',
      });
      expect(violations.map((v) => v.file), ['A.kt', 'B.kt', 'C.kt']);
    });

    test('the encrypted APIs and mentions in comments are allowed', () {
      final violations = checkKotlinSources({
        'A.kt':
            '// AndroidKeysetManager is not used\n'
            '/* nor CleartextKeysetHandle */\n'
            'TinkProtoKeysetFormat.serializeEncryptedKeyset(h, aead, ad)',
      });
      expect(violations, isEmpty);
    });
  });

  group('pubspec', () {
    test('networking and font-download packages are rejected', () {
      final violations = checkPubspec('dependencies:\n  http: ^1.0.0\n  google_fonts: ^6.0.0\n  drift: ^2.0.0\n');
      expect(violations.map((v) => v.message), [contains('http'), contains('google_fonts')]);
    });
  });

  test("the project's own pubspec passes", () {
    expect(checkPubspec(File('pubspec.yaml').readAsStringSync()), isEmpty);
  });
}
