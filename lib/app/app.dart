import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ledgerly/core/navigation/navigation_provider.dart';
import 'package:ledgerly/features/dashboard/dashboard.dart';
import 'package:ledgerly/theme/app_theme.dart';

class LedgerlyApp extends ConsumerWidget {
  const LedgerlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: ref.read(navigationProvider).navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Ledgerly',
      theme: AppTheme.darkTheme,
      home: const DashboardPage(),
    );
  }
}
