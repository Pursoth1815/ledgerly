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

/// Opens Set up backup (mockup `BackupSheet.dc.html`, screen 10i). Returns
/// true once backup is set up; the page then runs the first backup.
Future<bool> showBackupSetupSheet(BuildContext context) async =>
    await showLoopdSheet<bool>(context: context, builder: (_) => const BackupSetupSheet()) ?? false;

/// Passphrase twice, with live checks, and a folder from the phone's picker.
/// A sheet that fits its content (owner, 18 Nov 2026).
class BackupSetupSheet extends ConsumerStatefulWidget {
  const BackupSetupSheet({super.key});

  static const passphraseKey = ValueKey('backup-passphrase');
  static const againKey = ValueKey('backup-passphrase-again');

  @override
  ConsumerState<BackupSetupSheet> createState() => _BackupSetupSheetState();
}

class _BackupSetupSheetState extends ConsumerState<BackupSetupSheet> {
  final _passphrase = TextEditingController();
  final _again = TextEditingController();
  BackupFolder? _folder;
  bool _shown = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_passphrase, _again]) {
      c.addListener(() => setState(() => _error = null));
    }
  }

  @override
  void dispose() {
    _passphrase.dispose();
    _again.dispose();
    super.dispose();
  }

  bool get _long => _passphrase.text.length >= BackupEngine.passphraseMin;
  bool get _same => _passphrase.text.isNotEmpty && _passphrase.text == _again.text;

  Future<void> _pickFolder() async {
    FocusScope.of(context).unfocus();
    try {
      final folder = await ref.read(backupEngineProvider).pickFolder();
      if (folder != null && mounted) setState(() => _folder = folder);
    } on BackupException catch (e) {
      if (mounted) setState(() => _error = backupFailureText(e.failure));
    }
  }

  Future<void> _turnOn() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await ref.read(backupEngineProvider).setUp(passphrase: _passphrase.text, folder: _folder!);
      if (mounted) Navigator.of(context).pop(true);
    } on BackupException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = backupFailureText(e.failure);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ready = _long && _same && _folder != null && !_busy;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          header: true,
          child: Text('Set up backup', style: LoopdType.title.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(height: LoopdSpace.sm),
        Text(
          'Encrypted with your passphrase. Nothing is sent anywhere by the app.',
          style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: LoopdSpace.lg),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PassphraseField(
                  key: BackupSetupSheet.passphraseKey,
                  label: 'Passphrase',
                  hint: 'At least ${BackupEngine.passphraseMin} characters',
                  controller: _passphrase,
                  shown: _shown,
                  onToggle: () => setState(() => _shown = !_shown),
                ),
                const SizedBox(height: 10),
                PassphraseField(
                  key: BackupSetupSheet.againKey,
                  label: 'Type it again',
                  hint: 'The same again',
                  controller: _again,
                  shown: _shown,
                  onToggle: () => setState(() => _shown = !_shown),
                  wrong: _again.text.isNotEmpty && !_same,
                ),
                const SizedBox(height: LoopdSpace.md),
                PassphraseCheck(done: _long, text: 'At least ${BackupEngine.passphraseMin} characters'),
                const SizedBox(height: 6),
                PassphraseCheck(done: _same, text: 'Both match'),
                const SizedBox(height: LoopdSpace.lg),
                Text('Save backups to', style: LoopdType.caption.copyWith(color: c.textMuted)),
                const SizedBox(height: 6),
                _FolderChoice(folder: _folder, onPick: _pickFolder),
                const SizedBox(height: LoopdSpace.lg),
                const BackupNote(
                  'Keep it somewhere safe: Loopd never stores it. On this phone you can reset it with your '
                  'fingerprint or PIN; on a new phone, a backup can’t be opened without it.',
                ),
                if (_error != null) ...[const SizedBox(height: LoopdSpace.lg), LoopdErrorNote(_error!)],
                const SizedBox(height: LoopdSpace.lg),
              ],
            ),
          ),
        ),
        LoopdButton(label: _busy ? 'Setting up…' : 'Turn on and back up now', onTap: ready ? _turnOn : null),
      ],
    );
  }
}

/// A passphrase box with a show button. Shared by the backup sheets.
class PassphraseField extends StatelessWidget {
  const PassphraseField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.shown,
    required this.onToggle,
    this.wrong = false,
    super.key,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool shown;
  final VoidCallback onToggle;

  /// Draws a red border, such as when the two entries differ.
  final bool wrong;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final border = wrong ? c.danger : (controller.text.isEmpty ? c.surfaceRaised : c.vaultSolid);
    OutlineInputBorder outline(Color colour) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(LoopdRadius.inner),
      borderSide: BorderSide(color: colour, width: 1.5),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: LoopdType.caption.copyWith(color: c.textMuted)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: !shown,
          enableSuggestions: false,
          autocorrect: false,
          keyboardType: TextInputType.visiblePassword,
          style: LoopdType.bodyStrong.copyWith(color: c.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: LoopdType.body.copyWith(color: c.textMuted),
            filled: true,
            fillColor: c.surfaceRaised,
            contentPadding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: 14),
            enabledBorder: outline(border),
            focusedBorder: outline(wrong ? c.danger : c.vaultSolid),
            suffixIcon: IconButton(
              onPressed: onToggle,
              tooltip: shown ? 'Hide passphrase' : 'Show passphrase',
              icon: Icon(shown ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: c.textMuted),
            ),
          ),
        ),
      ],
    );
  }
}

/// A rule that turns green when met, such as "At least 12 characters".
class PassphraseCheck extends StatelessWidget {
  const PassphraseCheck({required this.done, required this.text, super.key});

  final bool done;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = LoopdMotion.of(context);
    return Semantics(
      container: true,
      label: '$text, ${done ? 'done' : 'not yet'}',
      excludeSemantics: true,
      child: Row(
        children: [
          AnimatedContainer(
            duration: motion.quick,
            width: 18,
            height: 18,
            decoration: BoxDecoration(color: done ? c.money : c.switchOff, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: 12, color: c.onAccent),
          ),
          const SizedBox(width: LoopdSpace.sm),
          Text(
            text,
            style: LoopdType.small.copyWith(color: done ? c.textPrimary : c.textMuted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// The yellow note with a warning sign.
class BackupNote extends StatelessWidget {
  const BackupNote(this.text, {this.danger = false, super.key});

  final String text;

  /// Red instead of yellow, such as before a restore.
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: danger ? c.dangerTint : c.lendingTint, borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.warning_amber_rounded, size: 18, color: danger ? c.danger : c.lending),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderChoice extends StatelessWidget {
  const _FolderChoice({required this.folder, required this.onPick});

  final BackupFolder? folder;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final f = folder;
    if (f == null) {
      return LoopdPressable(
        onTap: onPick,
        label: 'Choose a folder',
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LoopdRadius.inner),
            border: Border.all(color: c.vault, width: 1.5),
          ),
          child: Text('Choose a folder', style: LoopdType.label.copyWith(color: c.vault)),
        ),
      );
    }
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      padding: const EdgeInsets.only(left: 14, right: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LoopdRadius.inner),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: c.vaultTint, borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.folder_outlined, size: 18, color: c.vault),
          ),
          const SizedBox(width: LoopdSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.name, style: LoopdType.bodyStrong.copyWith(color: c.textPrimary)),
                Text(
                  'Loopd only writes here; it stays offline',
                  style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          SmallOutlineButton(label: 'Change', onTap: onPick),
        ],
      ),
    );
  }
}

/// A small outlined button, such as Change on a settings row.
class SmallOutlineButton extends StatelessWidget {
  const SmallOutlineButton({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      container: true,
      child: LoopdPressable(
        onTap: onTap,
        label: label,
        child: SizedBox(
          height: LoopdSize.minTouch,
          child: Center(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.md),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.line),
              ),
              child: Text(label, style: LoopdType.small.copyWith(color: c.textPrimary)),
            ),
          ),
        ),
      ),
    );
  }
}
