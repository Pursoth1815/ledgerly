import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/theme_setting.dart';
import '../../../design_system/components/loopd_card.dart';
import '../../../design_system/components/loopd_round_button.dart';
import '../../../design_system/components/loopd_toast.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'backup_card.dart';
import 'providers/today_providers.dart';
import 'spending_card.dart';
import 'today_date.dart';

/// Opens Backup & restore; passed in by `app/` (architecture rule 3).
typedef OpenBackup = Future<void> Function(BuildContext context);

/// Today shows only what needs attention (proposal section 3), and hides a
/// card that has nothing to say. So far Spending and Backup feed it; the other
/// cards arrive with their modules (Phases 3 to 8). With nothing to show it
/// is all clear.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({required this.onBackUp, this.clock = DateTime.now, super.key});

  /// The Backup card opens Backup & restore and starts a backup.
  final OpenBackup onBackUp;

  /// The current time; replaced in tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = clock();
    final month = ref.watch(todayMonthSpendingProvider(DateTime(now.year, now.month))).value;
    final backupAsync = ref.watch(todayBackupStatusProvider);
    final backup = backupAsync.value;
    // Nothing until all are read, so All clear never flashes before a card.
    // A backup status that cannot be read shows no nudge.
    final ready = month != null && (backup != null || backupAsync.hasError);
    final spending = ready && SpendingCard.hasSomething(month);
    final backupDue = ready && backup != null && BackupCard.isDue(backup, now);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          // Room at the bottom for the capture button.
          padding: const EdgeInsets.fromLTRB(LoopdSpace.gutter, 28, LoopdSpace.gutter, 120),
          children: [
            Text(
              todayDateLabel(now),
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
            // In the order of proposal section 3.
            if (spending) ...[SpendingCard(month: month, now: now), const SizedBox(height: LoopdSpace.lg)],
            if (backupDue) BackupCard(status: backup, now: now, onBackUp: () => onBackUp(context)),
            if (ready && !spending && !backupDue) const _AllClear(),
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
