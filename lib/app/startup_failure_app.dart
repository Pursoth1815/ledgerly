import 'package:flutter/material.dart';

import '../core/errors/app_exception.dart';

/// Shown instead of the app when its data cannot be opened.
///
/// Nothing is deleted or recreated. A temporary screen in stock widgets: the
/// recovery screen with "Restore from backup" is designed with backup in
/// Phase 2.
class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({required this.error, super.key});

  final AppException error;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Loopd',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(),
    darkTheme: ThemeData(brightness: Brightness.dark),
    home: Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Loopd cannot open your data', style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(_explanation, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 12),
                  Text(
                    'Nothing has been deleted. Restart the phone and open '
                    'Loopd again.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Text('Code: ${error.code}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );

  String get _explanation => switch (error) {
    KeyAccessException(failure: KeyAccessFailure.keyMissing) =>
      'The key that unlocks your data is missing from this phone.',
    KeyAccessException(failure: KeyAccessFailure.keyCorrupt) => 'The key that unlocks your data could not be read.',
    KeyAccessException(failure: KeyAccessFailure.keystoreUnavailable) =>
      "The phone's secure key storage did not respond.",
    DatabaseOpenException(failure: DatabaseOpenFailure.encryptionUnavailable) =>
      'This build cannot encrypt data, so it will not open any.',
    DatabaseOpenException(failure: DatabaseOpenFailure.keyMismatch) => 'The stored key does not match your data.',
    DatabaseOpenException(failure: DatabaseOpenFailure.openFailed) => 'Your data could not be opened.',
    LedgerException() => 'Your money records could not be set up.',
  };
}
