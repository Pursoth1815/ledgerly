import 'package:flutter/material.dart';

import '../../design_system/loopd_colors.dart';
import '../../design_system/loopd_spacing.dart';
import '../../design_system/loopd_typography.dart';
import 'app_tab.dart';

/// Stands in for a tab until its phase builds the real screen.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({required this.tab, super.key});

  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(LoopdSpace.gutter, 28, LoopdSpace.gutter, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(tab.label, style: LoopdType.display.copyWith(color: colors.textPrimary)),
              ),
              const SizedBox(height: LoopdSpace.sm),
              Text('Built in Phase ${tab.builtInPhase}', style: LoopdType.body.copyWith(color: colors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
