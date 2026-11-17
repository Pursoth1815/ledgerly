import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/theme_setting.dart';
import '../../../design_system/components/loopd_card.dart';
import '../../../design_system/components/loopd_round_button.dart';
import '../../../design_system/components/loopd_toast.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'today_date.dart';

/// Today shows only what needs attention (proposal section 3). Until the
/// modules that feed it are built (Phases 2 to 8), nothing does, so it shows
/// its empty state.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({this.clock = DateTime.now, super.key});

  /// The current time; replaced in tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          // Room at the bottom for the capture button.
          padding: const EdgeInsets.fromLTRB(LoopdSpace.gutter, 28, LoopdSpace.gutter, 120),
          children: [
            Text(
              todayDateLabel(clock()),
              style: LoopdType.small.copyWith(color: colors.textMuted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: LoopdSpace.xxs),
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text('Today', style: LoopdType.display.copyWith(color: colors.textPrimary)),
                  ),
                ),
                LoopdRoundButton(
                  icon: Icons.hourglass_empty_rounded,
                  label: 'Digital Wellbeing',
                  background: colors.wellbeingTint,
                  foreground: colors.wellbeing,
                  onTap: () => showLoopdToast(context, 'Digital Wellbeing is built in Phase 8'),
                ),
                const SizedBox(width: LoopdSpace.sm),
                LoopdRoundButton(
                  icon: isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  label: isDark ? 'Switch to light theme' : 'Switch to dark theme',
                  background: colors.surfaceRaised,
                  foreground: colors.textPrimary,
                  onTap: () => ref.read(themeSettingProvider.notifier).setDark(dark: !isDark),
                ),
              ],
            ),
            const SizedBox(height: LoopdSpace.xl),
            const _AllClear(),
          ],
        ),
      ),
    );
  }
}

/// Shown when no card has anything to say.
class _AllClear extends StatelessWidget {
  const _AllClear();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LoopdCard(
      semanticLabel: 'All clear. Nothing needs you right now.',
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: colors.moneyTint, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: 24, color: colors.money),
          ),
          const SizedBox(height: LoopdSpace.lg),
          Text('All clear', style: LoopdType.heading.copyWith(color: colors.textPrimary)),
          const SizedBox(height: LoopdSpace.xs),
          Text(
            'Nothing needs you right now. Payments to confirm, today\'s tasks, trips this week and '
            'money lent will show up here when they do.',
            style: LoopdType.body.copyWith(color: colors.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
