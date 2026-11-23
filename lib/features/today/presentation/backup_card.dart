import 'package:flutter/material.dart';

import '../../../core/backup/backup_engine.dart';
import '../../../design_system/components/loopd_dashed_button.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';

/// Today's Backup card (mockup `Main.dc.html`, screen 1): a nudge when the
/// last good backup is more than seven days old (proposal section 3). Its
/// button opens Backup & restore and starts a backup at once. While backups
/// are off it does not show; More says so instead.
class BackupCard extends StatelessWidget {
  const BackupCard({required this.status, required this.now, required this.onBackUp, super.key});

  final BackupStatus status;
  final DateTime now;
  final VoidCallback onBackUp;

  /// A backup is due after a week (proposal sections 3 and 11).
  static const dueAfter = Duration(days: 7);

  /// Whether the card has something to say.
  static bool isDue(BackupStatus status, DateTime now) {
    final last = status.lastBackupAt;
    return status.isSetUp && (last == null || now.difference(last) > dueAfter);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final last = status.lastBackupAt;
    final headline = last == null ? 'No backup yet' : 'Last backup ${now.difference(last).inDays} days ago';
    const button = 'Back up';
    return CustomPaint(
      painter: LoopdDashedBorder(c.line, 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(LoopdSpace.lg, 14, 14, 14),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                container: true,
                label: '$headline. Encrypted, to a folder you choose',
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(headline, style: LoopdType.label.copyWith(color: c.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      'Encrypted, to a folder you choose',
                      style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: LoopdSpace.md),
            Semantics(
              container: true,
              child: LoopdPressable(
                onTap: onBackUp,
                label: button,
                child: SizedBox(
                  height: LoopdSize.minTouch,
                  child: Center(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: BorderRadius.circular(20)),
                      child: Text(button, style: LoopdType.small.copyWith(color: c.textPrimary)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
