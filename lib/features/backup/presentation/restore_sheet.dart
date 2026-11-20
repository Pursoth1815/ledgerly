import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backup/backup_engine.dart';
import '../../../core/backup/backup_platform.dart';
import '../../../core/errors/app_exception.dart';
import '../../../design_system/components/loopd_button.dart';
import '../../../design_system/components/loopd_error_note.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_motion.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'backup_messages.dart';
import 'backup_setup_sheet.dart';
import 'backup_sheet.dart' show backupSizeText;

/// Opens Restore from a backup (mockup `BackupSheet.dc.html`, mode restore,
/// screen 10j). [folder] is where backups go on this phone, if set up; on a
/// new phone the owner picks the folder that holds them.
Future<void> showRestoreSheet(BuildContext context, {BackupFolder? folder}) => showLoopdSheet<void>(
  context: context,
  builder: (_) => RestoreSheet(folder: folder),
);

/// Choose a backup, type its passphrase, then replace everything with it.
/// The steps tick off as the engine works; nothing on the phone changes until
/// Loopd restarts to switch the restored data in.
class RestoreSheet extends ConsumerStatefulWidget {
  const RestoreSheet({this.folder, super.key});

  final BackupFolder? folder;

  static const passphraseKey = ValueKey('restore-passphrase');

  @override
  ConsumerState<RestoreSheet> createState() => _RestoreSheetState();
}

enum _Phase { choosing, running, done }

class _RestoreSheetState extends ConsumerState<RestoreSheet> {
  final _passphrase = TextEditingController();
  late BackupFolder? _folder = widget.folder;
  List<FoundBackup>? _backups;
  FoundBackup? _chosen;
  bool _loading = false;
  _Phase _phase = _Phase.choosing;
  RestoreStep? _step;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passphrase.addListener(() => setState(() => _error = null));
    if (_folder != null) _list(_folder!);
  }

  @override
  void dispose() {
    _passphrase.dispose();
    super.dispose();
  }

  Future<void> _list(BackupFolder folder) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final found = await ref.read(backupEngineProvider).listBackups(folder.uri);
      if (!mounted) return;
      setState(() {
        _folder = folder;
        _backups = found;
        _chosen = found.firstOrNull;
        _loading = false;
      });
    } on BackupException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _backups = null;
          _error = e.failure == BackupFailure.folderLost
              ? 'Loopd can’t open that folder any more. Choose it again.'
              : backupFailureText(e.failure);
        });
      }
    }
  }

  Future<void> _pickFolder() async {
    FocusScope.of(context).unfocus();
    try {
      final folder = await ref.read(backupEngineProvider).pickFolder();
      if (folder != null && mounted) await _list(folder);
    } on BackupException catch (e) {
      if (mounted) setState(() => _error = backupFailureText(e.failure));
    }
  }

  Future<void> _chooseAnother() async {
    FocusScope.of(context).unfocus();
    final backups = _backups ?? const [];
    final picked = await showLoopdSheet<Object>(
      context: context,
      builder: (_) => _BackupChoices(backups: backups, chosen: _chosen),
    );
    if (!mounted) return;
    if (picked is FoundBackup) setState(() => _chosen = picked);
    if (picked == _BackupChoices.anotherFolder) await _pickFolder();
  }

  Future<void> _restore() async {
    FocusScope.of(context).unfocus();
    final chosen = _chosen!;
    setState(() {
      _phase = _Phase.running;
      _error = null;
    });
    try {
      await ref
          .read(backupEngineProvider)
          .restore(
            folderUri: _folder!.uri,
            indexName: chosen.indexName,
            passphrase: _passphrase.text,
            onStep: (step) => setState(() => _step = step),
          );
      if (mounted) setState(() => _phase = _Phase.done);
    } on BackupException catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _Phase.choosing;
        _step = null;
        _error = restoreFailureText(e.failure);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final running = _phase == _Phase.running;
    final done = _phase == _Phase.done;
    final subtitle = switch (_phase) {
      _Phase.choosing => 'Choose a backup Loopd made, then its passphrase.',
      _Phase.running => 'Keep Loopd open. This takes a minute.',
      _Phase.done => 'Everything is back. Loopd restarts to finish.',
    };

    final Widget body;
    if (_phase != _Phase.choosing) {
      body = _Steps(step: done ? null : _step, done: done);
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _chooser(c),
          if (_chosen != null) ...[
            const SizedBox(height: LoopdSpace.lg),
            PassphraseField(
              key: RestoreSheet.passphraseKey,
              label: 'Passphrase of this backup',
              hint: 'The one you set for it',
              controller: _passphrase,
              wrong: _error != null && _passphrase.text.isNotEmpty,
            ),
          ],
          if (_error != null) ...[const SizedBox(height: LoopdSpace.lg), LoopdErrorNote(_error!)],
          const SizedBox(height: LoopdSpace.lg),
          const BackupNote(
            'Restoring replaces everything on this phone: money, notes, tasks, tickets and documents. '
            'What is here now stays until the restore is checked and done.',
            danger: true,
          ),
        ],
      );
    }

    final Widget button;
    if (done) {
      button = LoopdButton(label: 'Restart Loopd', onTap: () => ref.read(backupEngineProvider).restartToFinish());
    } else {
      final ready = _chosen != null && _passphrase.text.isNotEmpty && !running;
      button = LoopdButton(
        label: running ? 'Restoring…' : 'Replace with this backup',
        accent: c.danger,
        onTap: ready ? _restore : null,
      );
    }

    // Nothing may close the sheet half-way through.
    return PopScope(
      canPop: !running,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            header: true,
            child: Text('Restore from a backup', style: LoopdType.title.copyWith(color: c.textPrimary)),
          ),
          const SizedBox(height: LoopdSpace.sm),
          Text(
            subtitle,
            style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: LoopdSpace.lg),
          Flexible(child: SingleChildScrollView(child: body)),
          const SizedBox(height: LoopdSpace.lg),
          button,
        ],
      ),
    );
  }

  Widget _chooser(LoopdColors c) {
    if (_loading) {
      return const SizedBox(height: 72, child: Center(child: CircularProgressIndicator.adaptive()));
    }
    final chosen = _chosen;
    if (chosen != null) {
      return _BackupCard(backup: chosen, onChange: _chooseAnother);
    }
    final empty = _backups != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (empty) ...[
          Text(
            'No Loopd backups in ${_folder?.name ?? 'that folder'}.',
            style: LoopdType.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: LoopdSpace.md),
        ],
        LoopdPressable(
          onTap: _pickFolder,
          label: empty ? 'Choose another folder' : 'Choose the folder with your backups',
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LoopdRadius.inner),
              border: Border.all(color: c.vault, width: 1.5),
            ),
            child: Text(
              empty ? 'Choose another folder' : 'Choose the folder with your backups',
              style: LoopdType.label.copyWith(color: c.vault),
            ),
          ),
        ),
      ],
    );
  }
}

/// What to say when a restore stops.
String restoreFailureText(BackupFailure failure) => switch (failure) {
  BackupFailure.wrongPassphrase => 'That passphrase doesn’t open this backup. Check it, or choose another backup.',
  BackupFailure.notABackup => 'This backup was made by a newer Loopd, or it isn’t a Loopd backup. Nothing was changed.',
  BackupFailure.verifyFailed => 'This backup didn’t pass its checks, so nothing was changed. Try an older one.',
  _ => '${backupFailureText(failure)} Nothing was changed.',
};

/// "Backed up Sun 15 Nov, 02:00 · 43.6 MB · 1 part", from the run id.
String foundBackupText(FoundBackup backup) {
  final when = runIdDate(backup.runId);
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  String two(int n) => n.toString().padLeft(2, '0');
  final date = when == null
      ? 'Backed up'
      : 'Backed up ${days[when.weekday - 1]} ${when.day} ${months[when.month - 1]}, ${two(when.hour)}:${two(when.minute)}';
  final parts = backup.parts == 1 ? '1 part' : '${backup.parts} parts';
  return '$date · ${backupSizeText(backup.totalBytes)} · $parts';
}

/// The local time a run id starts with (`20261115-020000-…`), or null.
DateTime? runIdDate(String runId) {
  final m = RegExp(r'^(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})').firstMatch(runId);
  if (m == null) return null;
  final n = [for (var i = 1; i <= 6; i++) int.parse(m.group(i)!)];
  return DateTime(n[0], n[1], n[2], n[3], n[4], n[5]);
}

class _BackupCard extends StatelessWidget {
  const _BackupCard({required this.backup, required this.onChange});

  final FoundBackup backup;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, LoopdSpace.md, LoopdSpace.xs, LoopdSpace.md),
      decoration: BoxDecoration(color: c.vaultTint, borderRadius: BorderRadius.circular(LoopdRadius.card)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.vaultSolid, borderRadius: BorderRadius.circular(LoopdRadius.tile)),
            child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFFFFFFF), size: 22),
          ),
          const SizedBox(width: LoopdSpace.md),
          Expanded(
            child: Semantics(
              container: true,
              label: '${backup.indexName}, ${foundBackupText(backup)}',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    backup.indexName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LoopdType.code.copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    foundBackupText(backup),
                    style: LoopdType.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          SmallOutlineButton(label: 'Change', onTap: onChange),
        ],
      ),
    );
  }
}

/// Every backup in the folder, newest first, and another folder.
class _BackupChoices extends StatelessWidget {
  const _BackupChoices({required this.backups, required this.chosen});

  final List<FoundBackup> backups;
  final FoundBackup? chosen;

  static const anotherFolder = 'another-folder';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          header: true,
          child: Text('Choose a backup', style: LoopdType.title.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(height: LoopdSpace.lg),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final b in backups)
                  LoopdPressable(
                    onTap: () => Navigator.of(context).pop(b),
                    selected: b.indexName == chosen?.indexName,
                    label: foundBackupText(b),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 56),
                      padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.md),
                      margin: const EdgeInsets.only(bottom: LoopdSpace.sm),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(LoopdRadius.inner),
                        border: Border.all(color: b.indexName == chosen?.indexName ? c.vault : c.line, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(foundBackupText(b), style: LoopdType.small.copyWith(color: c.textPrimary)),
                          ),
                          if (b.indexName == chosen?.indexName) Icon(Icons.check_rounded, color: c.vault, size: 20),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: LoopdSpace.sm),
        LoopdButton(
          label: 'Another folder',
          style: LoopdButtonStyle.outlined,
          onTap: () => Navigator.of(context).pop(anotherFolder),
        ),
      ],
    );
  }
}

/// The five steps of a restore, ticked off as they finish (mockup 10j).
class _Steps extends StatelessWidget {
  const _Steps({required this.step, required this.done});

  /// The step under way; null once everything is done.
  final RestoreStep? step;
  final bool done;

  static const _labels = {
    RestoreStep.unlocking: 'Unlocked with your passphrase',
    RestoreStep.checkingParts: 'Checked every part',
    RestoreStep.restoring: 'Restored into a safe area',
    RestoreStep.checkingData: 'Checked your money and data',
    RestoreStep.switching: 'Ready to switch over',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = LoopdMotion.of(context);
    final current = done ? RestoreStep.values.length : (step?.index ?? 0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LoopdRadius.card),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          for (final s in RestoreStep.values)
            Semantics(
              container: true,
              label: '${_labels[s]}, ${s.index < current ? 'done' : (s.index == current ? 'under way' : 'waiting')}',
              excludeSemantics: true,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: motion.quick,
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: s.index < current ? c.money : const Color(0x00000000),
                        border: Border.all(color: s.index < current ? c.money : c.switchOff, width: 1.5),
                      ),
                      child: s.index < current ? Icon(Icons.check_rounded, size: 13, color: c.onAccent) : null,
                    ),
                    const SizedBox(width: LoopdSpace.md),
                    Expanded(
                      child: Text(
                        _labels[s]!,
                        style: LoopdType.label.copyWith(
                          color: s.index <= current ? c.textPrimary : c.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
