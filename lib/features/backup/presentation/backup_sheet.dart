import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backup/backup_engine.dart';
import '../../../core/errors/app_exception.dart';
import '../../../design_system/components/loopd_button.dart';
import '../../../design_system/components/loopd_error_note.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/components/loopd_switch.dart';
import '../../../design_system/components/loopd_toast.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_motion.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'backup_messages.dart';
import 'backup_setup_sheet.dart';
import 'passphrase_sheet.dart';
import 'providers/backup_providers.dart';
import 'restore_sheet.dart';

/// Opens Backup & restore (mockup `SettingsPage.dc.html`, page backup, screen
/// 10f) as a tall sheet over the whole app, tab bar included, like Accounts
/// and cards (owner, 19 Nov 2026; the mockup draws a page). No close button,
/// as on the other sheets: swipe it down or press back.
///
/// With [startNow], as from the Backup card on Today, it backs up at once, or
/// opens Set up backup when backups are off.
Future<void> showBackupSheet(BuildContext context, {bool startNow = false, DateTime Function() clock = DateTime.now}) =>
    showLoopdSheet<void>(
      context: context,
      tall: true,
      builder: (_) => BackupSheet(startNow: startNow, clock: clock),
    );

/// The status card with Back up now, where backups go, the passphrase, what
/// is inside, and Restore. Before setup, the card offers Set up backup.
///
/// Built in Phase 2, part 6. The weekly backup (Phase 7) says when it comes.
class BackupSheet extends ConsumerStatefulWidget {
  const BackupSheet({this.startNow = false, this.clock = DateTime.now, super.key});

  /// Back up (or set up) as soon as the status is read.
  final bool startNow;
  final DateTime Function() clock;

  @override
  ConsumerState<BackupSheet> createState() => _BackupSheetState();
}

class _BackupSheetState extends ConsumerState<BackupSheet> {
  BackupStage? _stage;
  bool _justDone = false;
  String? _error;
  late bool _startPending = widget.startNow;

  Future<void> _setUp() async {
    final done = await showBackupSetupSheet(context);
    if (done && mounted) await _backUp();
  }

  Future<void> _backUp() async {
    setState(() {
      _stage = BackupStage.copying;
      _error = null;
      _justDone = false;
    });
    try {
      await ref.read(backupEngineProvider).backUpNow(onStage: (stage) => setState(() => _stage = stage));
      if (mounted) setState(() => _justDone = true);
    } on BackupException catch (e) {
      if (mounted) setState(() => _error = backupFailureText(e.failure));
    } finally {
      if (mounted) setState(() => _stage = null);
    }
  }

  /// A changed passphrase means a new backup key, so back up at once.
  Future<void> _changePassphrase() async {
    final outcome = await showPassphraseSheet(context);
    if (outcome == PassphraseOutcome.changed && mounted) {
      showLoopdToast(context, 'Passphrase changed. Backing up with it now');
      await _backUp();
    }
  }

  Future<void> _changeFolder() async {
    final engine = ref.read(backupEngineProvider);
    try {
      final folder = await engine.pickFolder();
      if (folder == null) return;
      await engine.changeFolder(folder);
      if (mounted) {
        setState(() => _error = null);
        showLoopdToast(context, 'Backups now go to ${folder.name}');
      }
    } on BackupException catch (e) {
      if (mounted) setState(() => _error = backupFailureText(e.failure));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final statusAsync = ref.watch(backupStatusProvider);
    final status = statusAsync.value;
    if (_startPending && status != null) {
      _startPending = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(status.isSetUp ? _backUp() : _setUp());
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          header: true,
          child: Text('Backup & restore', style: LoopdType.title.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(height: LoopdSpace.sm),
        Text(
          'Encrypted with your passphrase. Nothing is sent anywhere by the app.',
          style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: LoopdSpace.lg),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (statusAsync.hasError)
                const LoopdErrorNote('Backup status could not be loaded. Close this and open it again.')
              else if (status != null) ...[
                _StatusCard(
                  status: status,
                  stage: _stage,
                  justDone: _justDone,
                  now: widget.clock(),
                  onSetUp: _setUp,
                  onBackUp: _backUp,
                ),
                if (_error != null) ...[const SizedBox(height: LoopdSpace.md), LoopdErrorNote(_error!)],
                if (status.isSetUp) ...[
                  const SizedBox(height: LoopdSpace.xl),
                  _Settings(
                    status: status,
                    busy: _stage != null,
                    onChangeFolder: _changeFolder,
                    onChangePassphrase: _changePassphrase,
                  ),
                  if (status.lastBackupBytes != null) ...[
                    const SizedBox(height: LoopdSpace.xl),
                    _Inside(bytes: status.lastBackupBytes!),
                  ],
                ],
                const SizedBox(height: LoopdSpace.xl),
                LoopdButton(
                  label: 'Restore from a backup file',
                  style: LoopdButtonStyle.outlined,
                  onTap: () => showRestoreSheet(
                    context,
                    folder: status.folderUri == null ? null : (uri: status.folderUri!, name: status.folderName ?? ''),
                  ),
                ),
                const SizedBox(height: 10),
                const BackupNote(
                  'Restoring replaces everything on this phone. A forgotten passphrase can’t be recovered, '
                  'so keep it somewhere safe.',
                ),
                const SizedBox(height: LoopdSpace.lg),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// The coloured card: blue while a backup is due or running, green once one
/// is recent and checked (mockup 10f).
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.stage,
    required this.justDone,
    required this.now,
    required this.onSetUp,
    required this.onBackUp,
  });

  final BackupStatus status;
  final BackupStage? stage;
  final bool justDone;
  final DateTime now;
  final VoidCallback onSetUp;
  final VoidCallback onBackUp;

  /// A backup is due after a week (proposal section 11, the Today nudge).
  static const dueAfter = Duration(days: 7);

  static const _white = Color(0xFFFFFFFF);
  static const _white22 = Color(0x38FFFFFF);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = LoopdMotion.of(context);
    final running = stage != null;
    final last = status.lastBackupAt;
    final recent = last != null && now.difference(last) < dueAfter;
    final safe = status.isSetUp && !running && (justDone || recent);
    // The deep green and blue of the mockup, the same in both themes.
    final background = safe ? LoopdColors.light.money : c.vaultSolid;

    final String headline;
    final String sub;
    final String chip;
    final String button;
    if (!status.isSetUp) {
      (headline, sub, chip, button) = ('Backups are off', 'Set up a passphrase and a folder', 'Off', 'Set up backup');
    } else if (running) {
      headline = 'Backing up…';
      sub = switch (stage!) {
        BackupStage.copying => 'Copying your data',
        BackupStage.encrypting => 'Encrypting it into the folder',
        BackupStage.checking => 'Reading it back to check it',
        BackupStage.tidying => 'Keeping the last ${BackupEngine.keep}',
      };
      (chip, button) = ('…', 'Please wait');
    } else if (justDone) {
      (headline, sub, chip, button) = (
        'Backed up just now',
        'Checked, and kept with the last ${BackupEngine.keep}',
        'Safe',
        'Back up again',
      );
    } else if (last == null) {
      (headline, sub, chip, button) = ('No backup yet', 'Back up now to keep your data safe', 'Due', 'Back up now');
    } else {
      headline = 'Last backup ${_ago(last, now)}';
      sub = recent ? 'Checked, and kept with the last ${BackupEngine.keep}' : 'A backup is due';
      (chip, button) = (recent ? 'Safe' : 'Due', 'Back up now');
    }
    final progress = !status.isSetUp
        ? 0.0
        : running
        ? (stage!.index + 1) / BackupStage.values.length
        : (safe ? 1.0 : 0.12);

    return AnimatedContainer(
      duration: motion.standard,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(LoopdRadius.section)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            liveRegion: true,
            label: '$headline. $sub',
            excludeSemantics: true,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: _white22, borderRadius: BorderRadius.circular(LoopdRadius.tile)),
                  child: const Icon(Icons.verified_user_outlined, color: _white, size: 22),
                ),
                const SizedBox(width: LoopdSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(headline, style: LoopdType.heading.copyWith(color: _white, fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(
                        sub,
                        style: LoopdType.small.copyWith(color: _white, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: LoopdSpace.xs),
                  decoration: BoxDecoration(color: _white22, borderRadius: BorderRadius.circular(LoopdRadius.pill)),
                  child: Text(
                    chip,
                    style: LoopdType.caption.copyWith(color: _white, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LoopdSpace.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Container(height: 6, color: _white22),
                AnimatedFractionallySizedBox(
                  duration: motion.emphasis,
                  widthFactor: progress,
                  child: Container(height: 6, color: _white),
                ),
              ],
            ),
          ),
          const SizedBox(height: LoopdSpace.lg),
          Semantics(
            container: true,
            child: LoopdPressable(
              onTap: running ? null : (status.isSetUp ? onBackUp : onSetUp),
              label: button,
              child: AnimatedOpacity(
                duration: motion.quick,
                opacity: running ? 0.4 : 1,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(color: _white, borderRadius: BorderRadius.circular(25)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        status.isSetUp ? Icons.cloud_upload_outlined : Icons.lock_outline_rounded,
                        size: 18,
                        color: background,
                      ),
                      const SizedBox(width: LoopdSpace.sm),
                      Text(
                        button,
                        style: LoopdType.label.copyWith(color: background, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "today", "yesterday", "9 days ago".
  static String _ago(DateTime at, DateTime now) {
    final days = DateTime(now.year, now.month, now.day).difference(DateTime(at.year, at.month, at.day)).inDays;
    return switch (days) {
      <= 0 => 'today',
      1 => 'yesterday',
      _ => '$days days ago',
    };
  }
}

class _Settings extends StatelessWidget {
  const _Settings({
    required this.status,
    required this.busy,
    required this.onChangeFolder,
    required this.onChangePassphrase,
  });

  final BackupStatus status;
  final bool busy;
  final VoidCallback onChangeFolder;
  final VoidCallback onChangePassphrase;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    Widget row({required String title, required String sub, required Widget trailing}) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: LoopdType.body.copyWith(color: c.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: 2),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(LoopdRadius.cardLarge),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          row(
            title: 'Save to',
            sub: '${status.folderName ?? 'No folder'} · picked with the phone’s file picker',
            trailing: SmallOutlineButton(label: 'Change', onTap: busy ? null : onChangeFolder),
          ),
          Divider(height: 1, thickness: 1, color: c.line),
          row(
            title: 'Weekly automatic backup',
            sub: 'Comes in Phase 7',
            trailing: LoopdSwitch(
              value: false,
              onChanged: null,
              label: 'Weekly automatic backup',
              activeColor: c.vault,
            ),
          ),
          Divider(height: 1, thickness: 1, color: c.line),
          row(
            title: 'Passphrase',
            sub: 'Set · needed to open a backup',
            trailing: SmallOutlineButton(label: 'Change', onTap: busy ? null : onChangePassphrase),
          ),
        ],
      ),
    );
  }
}

/// What is inside a backup, and its size. Until the Vault and tickets arrive,
/// it is your money, notes and tasks.
class _Inside extends StatelessWidget {
  const _Inside({required this.bytes});

  final int bytes;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = backupSizeText(bytes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          header: true,
          child: Text('In every backup · $size', style: LoopdType.small.copyWith(color: c.textMuted)),
        ),
        const SizedBox(height: 10),
        Container(
          height: 10,
          decoration: BoxDecoration(color: c.money, borderRadius: BorderRadius.circular(5)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c.money, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Money, notes and tasks $size',
                style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// "43.6 MB", "820 KB".
String backupSizeText(int bytes) {
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / 1024).ceil()} KB';
}
