import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import 'app_tab.dart';

/// Stands in for a tab until its phase builds the real screen.
class PlaceholderPage extends ConsumerWidget {
  const PlaceholderPage({required this.tab, super.key});

  final AppTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final build = switch (ref.watch(appConfigProvider).distribution) {
      Distribution.personal => 'Personal build',
      Distribution.store => 'Store build',
    };
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tab.label, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Built in Phase ${tab.builtInPhase}', style: theme.textTheme.bodyLarge),
              if (tab == AppTab.more) ...[const SizedBox(height: 8), Text(build, style: theme.textTheme.bodyMedium)],
            ],
          ),
        ),
      ),
    );
  }
}
