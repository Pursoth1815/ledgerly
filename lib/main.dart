import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/app/app.dart';
import 'package:ledgerly/app/app_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// FLAVOR INITIALIZE ////
  const flavor = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'prod',
  );

  // Create container so we can prefetch providers
  final container = ProviderContainer();

  // 🔥 REAL USE: app boot sequence
  await AppInitializer.initialize(container: container, flavor: flavor);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: LedgerlyApp(),
    ),
  );
}
