import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backup/backup_engine.dart';
import '../../../core/errors/app_exception.dart';
import '../../../design_system/components/loopd_button.dart';
import '../../../design_system/components/loopd_error_note.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/components/loopd_round_button.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/components/loopd_toast.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'backup_messages.dart';
import 'backup_setup_sheet.dart';

/// What the passphrase sheet did.
enum PassphraseOutcome {
  /// A new backup key with a new passphrase: back up now (ADR 0011).
  changed,

  /// The same key with a new passphrase, after a fingerprint or PIN check.
  reset,
}

/// Opens Change passphrase (mockup `BackupSheet.dc.html`, mode change, screen
/// 10k), with Forgot it? leading to the reset (mode forgot, 10l).
Future<PassphraseOutcome?> showPassphraseSheet(BuildContext context) =>
    showLoopdSheet<PassphraseOutcome>(context: context, builder: (_) => const PassphraseSheet());

/// Change passphrase, or reset a forgotten one on this phone. One sheet with
/// two views, as in the mockups; it fits its content.
class PassphraseSheet extends ConsumerStatefulWidget {
  const PassphraseSheet({super.key});

  static const currentKey = ValueKey('passphrase-current');
  static const newKey = ValueKey('passphrase-new');
  static const againKey = ValueKey('passphrase-again');

  @override
  ConsumerState<PassphraseSheet> createState() => _PassphraseSheetState();
}

class _PassphraseSheetState extends ConsumerState<PassphraseSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();
  bool _forgot = false;
  bool _confirmed = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    for (final c in [_current, _next, _again]) {
      c.addListener(() => setState(() => _error = null));
    }
  }

  @override
  void dispose() {
    for (final c in [_current, _next, _again]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _long => _next.text.length >= BackupEngine.passphraseMin;
  bool get _same => _next.text.isNotEmpty && _next.text == _again.text;

  void _toForgot() => setState(() {
    _forgot = true;
    _confirmed = false;
    _error = null;
    _next.clear();
    _again.clear();
  });

  void _toChange() => setState(() {
    _forgot = false;
    _error = null;
    _next.clear();
    _again.clear();
  });

  Future<void> _confirm() async {
    try {
      final ok = await ref.read(backupEngineProvider).confirmOwner();
      if (mounted) setState(() => _confirmed = ok);
    } on BackupException catch (e) {
      if (mounted) setState(() => _error = backupFailureText(e.failure));
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    final engine = ref.read(backupEngineProvider);
    try {
      if (_forgot) {
        await engine.resetPassphrase(_next.text);
        if (!mounted) return;
        showLoopdToast(context, 'New backups use your new passphrase');
        Navigator.of(context).pop(PassphraseOutcome.reset);
      } else {
        await engine.changePassphrase(current: _current.text, next: _next.text);
        if (mounted) Navigator.of(context).pop(PassphraseOutcome.changed);
      }
    } on BackupException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = switch (e.failure) {
          BackupFailure.wrongPassphrase => 'That isn’t your current passphrase. Try again, or use Forgot it?',
          BackupFailure.cancelled => 'Confirm it’s you again, then save.',
          _ => backupFailureText(e.failure),
        };
        if (e.failure == BackupFailure.cancelled) _confirmed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ready = !_busy && _long && _same && (_forgot ? _confirmed : _current.text.isNotEmpty);
    final title = _forgot ? 'Forgot your passphrase' : 'Change passphrase';
    final subtitle = _forgot
        ? 'Set a new one on this phone after a quick check.'
        : 'For new backups. Loopd makes a fresh one at once.';
    final showNew = !_forgot || _confirmed;
    return PopScope(
      canPop: !_forgot,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _toChange();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (_forgot) ...[
                Semantics(
                  container: true,
                  child: LoopdRoundButton(
                    icon: Icons.chevron_left_rounded,
                    iconSize: 22,
                    label: 'Back to Change passphrase',
                    size: 40,
                    background: c.surfaceRaised,
                    foreground: c.textPrimary,
                    onTap: _toChange,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Semantics(
                  container: true,
                  header: true,
                  child: Text(title, style: LoopdType.title.copyWith(color: c.textPrimary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: LoopdSpace.sm),
          Text(
            subtitle,
            style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: LoopdSpace.lg),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_forgot) ...[
                    _OwnerCheck(confirmed: _confirmed, onCheck: _confirm),
                    const SizedBox(height: LoopdSpace.lg),
                  ] else ...[
                    PassphraseField(
                      key: PassphraseSheet.currentKey,
                      label: 'Current passphrase',
                      hint: 'The one you use now',
                      controller: _current,
                      wrong: _error != null && _current.text.isNotEmpty,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        container: true,
                        child: LoopdPressable(
                          onTap: _toForgot,
                          label: 'Forgot it?',
                          child: SizedBox(
                            height: LoopdSize.minTouch,
                            // Only as wide as the words, on the left (mockup 10k).
                            child: Align(
                              alignment: Alignment.centerLeft,
                              widthFactor: 1,
                              child: Text('Forgot it?', style: LoopdType.small.copyWith(color: c.vault)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (showNew) ...[
                    PassphraseField(
                      key: PassphraseSheet.newKey,
                      label: 'New passphrase',
                      hint: 'At least ${BackupEngine.passphraseMin} characters',
                      controller: _next,
                    ),
                    const SizedBox(height: 10),
                    PassphraseField(
                      key: PassphraseSheet.againKey,
                      label: 'Type it again',
                      hint: 'The same again',
                      controller: _again,
                      wrong: _again.text.isNotEmpty && !_same,
                    ),
                    const SizedBox(height: LoopdSpace.md),
                    PassphraseCheck(done: _long, text: 'At least ${BackupEngine.passphraseMin} characters'),
                    const SizedBox(height: 6),
                    PassphraseCheck(done: _same, text: 'Both match'),
                    const SizedBox(height: LoopdSpace.lg),
                  ],
                  if (_error != null) ...[LoopdErrorNote(_error!), const SizedBox(height: LoopdSpace.lg)],
                  BackupNote(
                    _forgot
                        ? 'New backups use the new passphrase. Backups made before still need the old one, '
                              'so keep them only if you remember it.'
                        : 'Backups made before still need the old passphrase.',
                  ),
                  const SizedBox(height: LoopdSpace.lg),
                ],
              ),
            ),
          ),
          LoopdButton(
            label: _busy ? 'Saving…' : (_forgot ? 'Save new passphrase' : 'Change and back up'),
            onTap: ready ? _save : null,
          ),
        ],
      ),
    );
  }
}

/// "Confirm it's you", then "It's you" once the phone's check passes.
class _OwnerCheck extends StatelessWidget {
  const _OwnerCheck({required this.confirmed, required this.onCheck});

  final bool confirmed;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, LoopdSpace.sm, 14),
      decoration: BoxDecoration(
        color: confirmed ? c.moneyTint : c.vaultTint,
        borderRadius: BorderRadius.circular(LoopdRadius.card),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: confirmed ? c.money : c.vaultSolid,
              borderRadius: BorderRadius.circular(LoopdRadius.tile),
            ),
            child: Icon(Icons.fingerprint_rounded, color: confirmed ? c.onAccent : const Color(0xFFFFFFFF), size: 24),
          ),
          const SizedBox(width: LoopdSpace.md),
          Expanded(
            child: Semantics(
              container: true,
              liveRegion: true,
              label: confirmed
                  ? 'It’s you. Checked on this phone'
                  : 'Confirm it’s you. Fingerprint, face or your phone’s PIN',
              excludeSemantics: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    confirmed ? 'It’s you' : 'Confirm it’s you',
                    style: LoopdType.bodyStrong.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    confirmed ? 'Checked on this phone' : 'Fingerprint, face or your phone’s PIN',
                    style: LoopdType.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          if (!confirmed)
            Semantics(
              container: true,
              child: LoopdPressable(
                onTap: onCheck,
                label: 'Check',
                child: SizedBox(
                  height: LoopdSize.minTouch,
                  child: Center(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: c.vaultSolid, borderRadius: BorderRadius.circular(20)),
                      child: Text('Check', style: LoopdType.small.copyWith(color: const Color(0xFFFFFFFF))),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
