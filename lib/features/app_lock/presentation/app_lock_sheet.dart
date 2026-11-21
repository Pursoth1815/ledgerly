import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/app_lock_setting.dart';
import '../../../design_system/components/loopd_error_note.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/components/loopd_switch.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_motion.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'providers/app_lock_providers.dart';

/// Opens App lock (mockup `AppLock.dc.html`, mode settings, screen 10m): a
/// sheet that fits its content.
Future<void> showAppLockSheet(BuildContext context) =>
    showLoopdSheet<void>(context: context, builder: (_) => const AppLockSheet());

class AppLockSheet extends ConsumerStatefulWidget {
  const AppLockSheet({super.key});

  @override
  ConsumerState<AppLockSheet> createState() => _AppLockSheetState();
}

class _AppLockSheetState extends ConsumerState<AppLockSheet> {
  bool _busy = false;
  String? _error;

  Future<void> _toggle(bool on) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final refusal = await ref.read(appLockProvider.notifier).setEnabled(on: on);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = switch (refusal) {
        AppLockRefusal.noScreenLock => 'Your phone has no screen lock yet. Set a fingerprint or PIN in the phone’s Settings › Security, then turn this on.',
        AppLockRefusal.notConfirmed => 'App lock stays off: the check was cancelled.',
        null => null,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = ref.watch(appLockProvider.select((s) => s.settings));
    final after = settings.afterMinutes == 0 ? 'every time you come back' : 'after ${settings.afterMinutes} min away';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          header: true,
          child: Text('App lock', style: LoopdType.title.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(height: LoopdSpace.sm),
        Text(
          'Fingerprint, face or your phone’s PIN to open Loopd.',
          style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: LoopdSpace.lg),
        Container(
          constraints: const BoxConstraints(minHeight: 68),
          padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: LoopdSpace.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(LoopdRadius.cardLarge),
            border: Border.all(color: c.line),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: c.vaultTint, borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.lock_outline_rounded, color: c.vault, size: 20),
              ),
              const SizedBox(width: LoopdSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Lock Loopd', style: LoopdType.bodyStrong.copyWith(color: c.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      settings.enabled ? 'On · asks $after' : 'Off',
                      style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              LoopdSwitch(
                value: settings.enabled,
                label: 'Lock Loopd',
                activeColor: c.vaultSolid,
                onChanged: _busy ? null : _toggle,
              ),
            ],
          ),
        ),
        if (_error != null) ...[const SizedBox(height: LoopdSpace.lg), LoopdErrorNote(_error!)],
        const SizedBox(height: LoopdSpace.lg),
        if (settings.enabled) ...[
          Text('Lock again after Loopd is away for', style: LoopdType.caption.copyWith(color: c.textMuted)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (i, minutes) in AppLockSettings.choices.indexed) ...[
                if (i > 0) const SizedBox(width: LoopdSpace.sm),
                Expanded(
                  child: _TimeChoice(
                    label: minutes == 0 ? 'Now' : '$minutes min',
                    selected: minutes == settings.afterMinutes,
                    onTap: () => ref.read(appLockProvider.notifier).setAfterMinutes(minutes),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: LoopdSpace.lg),
          _Note(
            icon: Icons.visibility_off_outlined,
            colour: c.vault,
            tint: c.vaultTint,
            text: 'While App lock is on, Loopd is hidden in recent apps and screenshots are blocked.',
          ),
        ] else
          _Note(
            icon: Icons.info_outline_rounded,
            colour: c.lending,
            tint: c.lendingTint,
            text:
                'Turning it on asks for your fingerprint or PIN once, to be sure it works. '
                'Your data stays encrypted either way.',
          ),
      ],
    );
  }
}

class _TimeChoice extends StatelessWidget {
  const _TimeChoice({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LoopdPressable(
      onTap: onTap,
      selected: selected,
      label: label,
      child: AnimatedContainer(
        duration: LoopdMotion.of(context).quick,
        height: LoopdSize.minTouch,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.vaultSolid : const Color(0x00000000),
          borderRadius: BorderRadius.circular(LoopdRadius.pill),
          border: Border.all(color: selected ? c.vaultSolid : c.line),
        ),
        child: Text(
          label,
          style: LoopdType.small.copyWith(color: selected ? const Color(0xFFFFFFFF) : c.textSecondary),
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.colour, required this.tint, required this.text});

  final IconData icon;
  final Color colour;
  final Color tint;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(18)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 18, color: colour),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: LoopdType.small.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ),
      ],
    ),
  );
}
