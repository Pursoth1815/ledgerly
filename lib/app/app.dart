import 'package:flutter/material.dart';
import 'package:ledgerly/features/dashboard/dashboard.dart';
import 'package:ledgerly/theme/app_theme.dart';

class LedgerlyApp extends StatelessWidget {
  const LedgerlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ledgerly',
      theme: AppTheme.darkTheme,
      home: const DashboardPage(),
    );
  }
}
