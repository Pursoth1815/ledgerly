import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_paths.dart';
import '../../design_system/components/loopd_button.dart';
import '../../design_system/loopd_colors.dart';
import '../../design_system/loopd_spacing.dart';
import '../../design_system/loopd_typography.dart';
import '../config/app_config.dart';
import 'app_tab.dart';

/// Stands in for a tab until its phase builds the real screen.
class PlaceholderPage extends ConsumerWidget {
  const PlaceholderPage({required this.tab, super.key});

  final AppTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final build = switch (ref.watch(appConfigProvider).distribution) {
      Distribution.personal => 'Personal build',
      Distribution.store => 'Store build',
    };
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(LoopdSpace.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tab.label, style: LoopdType.display.copyWith(color: colors.textPrimary)),
              const SizedBox(height: LoopdSpace.sm),
              Text('Built in Phase ${tab.builtInPhase}', style: LoopdType.body.copyWith(color: colors.textSecondary)),
              if (tab == AppTab.more) ...[
                const SizedBox(height: LoopdSpace.sm),
                Text(build, style: LoopdType.small.copyWith(color: colors.textMuted)),
                if (!kReleaseMode) ...[
                  const SizedBox(height: LoopdSpace.xxl),
                  LoopdButton(
                    label: 'Component gallery',
                    style: LoopdButtonStyle.outlined,
                    onTap: () => context.push(RoutePaths.gallery),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
