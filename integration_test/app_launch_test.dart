import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:loopd/app/bootstrap.dart';
import 'package:loopd/app/shell/loopd_tab_bar.dart';
import 'package:loopd/core/database/database_opener.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Phase 0A's "tested when": the app launches into the five-tab shell on a
/// device and its database file is encrypted (Android only).
///
///   flutter test integration_test --flavor personal
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launches into the shell with an encrypted database', (tester) async {
    await bootstrap();
    await tester.pumpAndSettle();

    expect(find.byType(LoopdTabBar), findsOneWidget);
    expect(find.text('Built in Phase 1'), findsOneWidget);

    final directory = await getApplicationSupportDirectory();
    final file = File(p.join(directory.path, databaseFileName));
    expect(file.existsSync(), isTrue);
    final header = String.fromCharCodes(file.openSync().readSync(16));
    expect(header, isNot(startsWith('SQLite format 3')));
  });
}
