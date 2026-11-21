import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/route_paths.dart';
import '../../core/settings/theme_setting.dart';
import '../../design_system/components/loopd_button.dart';
import '../../design_system/components/loopd_pressable.dart';
import '../../design_system/components/loopd_switch.dart';
import '../../design_system/components/loopd_toast.dart';
import '../../design_system/loopd_colors.dart';
import '../../design_system/loopd_spacing.dart';
import '../../design_system/loopd_typography.dart';
import '../../features/accounts/accounts.dart';
import '../../features/app_lock/app_lock.dart';
import '../../features/backup/backup.dart';
import '../../features/expenses/expenses.dart';
import '../config/app_config.dart';

/// The More tab (proposal section 3, mockup `More.dc.html`): the Vault and
/// Screen time tiles, then settings in four groups. Rows show which phase
/// builds them; Accounts and cards and the Dark theme switch work so far.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final personal = ref.watch(appConfigProvider).distribution == Distribution.personal;
    void soon(String what, String when) => showLoopdToast(context, '$what is built $when');
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(LoopdSpace.gutter, 28, LoopdSpace.gutter, 120),
          children: [
            Semantics(
              header: true,
              child: Text('More', style: LoopdType.display.copyWith(color: c.textPrimary)),
            ),
            const SizedBox(height: 6),
            Text(
              'Everything stays on this phone.',
              style: LoopdType.label.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: LoopdSpace.xl),
            Row(
              children: [
                Expanded(
                  child: _Tile(
                    title: 'Vault',
                    subtitle: 'Phase 7',
                    icon: Icons.folder_special_outlined,
                    backdrop: Icons.shield_outlined,
                    color: c.vaultSolid,
                    onTap: () => soon('The Vault', 'in Phase 7'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Tile(
                    title: 'Screen time',
                    subtitle: 'Phase 8',
                    icon: Icons.hourglass_empty_rounded,
                    backdrop: Icons.timer_outlined,
                    color: const Color(0xFF0F766E),
                    onTap: () => soon('Screen time', 'in Phase 8'),
                  ),
                ),
              ],
            ),
            _Group(
              name: 'Money',
              rows: [
                _LinkRow(
                  // No count on the right (owner's choice, 18 Nov 2026).
                  label: 'Accounts and cards',
                  dot: c.money,
                  tint: c.moneyTint,
                  onTap: () => showAccountsSheet(context),
                ),
                _LinkRow(
                  label: 'Expense categories',
                  hint: 'Food, Travel, Shopping and your own',
                  dot: c.money,
                  tint: c.moneyTint,
                  onTap: () => showCategorySheet(context),
                ),
                // The store build never reads SMS (ADR 0017).
                if (personal)
                  _SwitchRow(
                    label: 'SMS detection',
                    hint: 'Turns bank messages into cards to confirm',
                    dot: c.review,
                    tint: c.reviewTint,
                    value: false,
                    activeColor: c.review,
                    onChanged: null,
                  ),
              ],
            ),
            _Group(
              name: 'Reminders',
              rows: [
                _SwitchRow(
                  label: 'Task reminders',
                  hint: 'Phase 6',
                  dot: c.notes,
                  tint: c.notesTint,
                  value: false,
                  activeColor: c.notes,
                  onChanged: null,
                ),
              ],
            ),
            _Group(
              name: 'Privacy and backup',
              rows: [
                _LinkRow(
                  label: 'App lock',
                  value: ref.watch(appLockProvider.select((s) => s.settings.enabled)) ? 'On' : 'Off',
                  dot: c.vault,
                  tint: c.vaultTint,
                  onTap: () => showAppLockSheet(context),
                ),
                _LinkRow(
                  label: 'Backup & restore',
                  dot: c.vault,
                  tint: c.vaultTint,
                  onTap: () => showBackupSheet(context),
                ),
                _LinkRow(
                  label: 'Export logs',
                  value: 'Phase 11',
                  dot: c.textMuted,
                  tint: c.surfaceRaised,
                  onTap: () => soon('Export logs', 'in Phase 11'),
                ),
              ],
            ),
            _Group(
              name: 'Appearance',
              rows: [
                _SwitchRow(
                  label: 'Dark theme',
                  dot: c.themeSwitch,
                  tint: c.creditCardTint,
                  value: isDark,
                  activeColor: c.themeSwitch,
                  onChanged: (dark) => ref.read(themeSettingProvider.notifier).setDark(dark: dark),
                ),
              ],
            ),
            const SizedBox(height: LoopdSpace.xxl),
            Center(
              child: Text(
                personal ? 'Personal build' : 'Store build',
                style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
              ),
            ),
            if (!kReleaseMode) ...[
              const SizedBox(height: LoopdSpace.md),
              LoopdButton(
                label: 'Component gallery',
                style: LoopdButtonStyle.outlined,
                onTap: () => context.push(RoutePaths.gallery),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A solid colour tile with a large faint icon (review round 4).
class _Tile extends StatelessWidget {
  const _Tile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backdrop,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  /// The large faint picture in the bottom-right corner.
  final IconData backdrop;
  final Color color;
  final VoidCallback onTap;

  static const _white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) => LoopdPressable(
    onTap: onTap,
    label: '$title, $subtitle',
    child: Container(
      height: 148,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(LoopdRadius.section)),
      child: Stack(
        children: [
          // As in the mockup: 120 px, 14% white, off the bottom-right corner.
          Positioned(right: -26, bottom: -28, child: Icon(backdrop, size: 120, color: _white.withValues(alpha: 0.14))),
          Padding(
            padding: const EdgeInsets.all(LoopdSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(LoopdRadius.tile),
                  ),
                  child: Icon(icon, size: 22, color: _white),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: LoopdType.heading.copyWith(color: _white)),
                    Text(
                      subtitle,
                      style: LoopdType.caption.copyWith(color: _white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// A titled group of rows on one card, with hairlines between rows.
class _Group extends StatelessWidget {
  const _Group({required this.name, required this.rows});

  final String name;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: LoopdSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(name, style: LoopdType.small.copyWith(color: c.textMuted)),
          ),
          const SizedBox(height: LoopdSpace.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(LoopdRadius.card),
              border: Border.all(color: c.line),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: LoopdSpace.xxs),
              child: Column(
                children: [
                  for (final (index, row) in rows.indexed) ...[
                    if (index > 0) Divider(height: 1, thickness: 1, color: c.line),
                    row,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The coloured dot and the label, shared by both kinds of row.
class _RowStart extends StatelessWidget {
  const _RowStart({required this.label, required this.dot, required this.tint, this.hint});

  final String label;
  final String? hint;
  final Color dot;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(10)),
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
            ),
          ),
          const SizedBox(width: LoopdSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: LoopdType.body.copyWith(color: c.textPrimary)),
                if (hint != null)
                  Text(
                    hint!,
                    style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.dot,
    required this.tint,
    required this.onTap,
    this.value,
    this.hint,
  });

  final String label;

  /// Muted text before the chevron, such as the phase that builds the row.
  final String? value;
  final String? hint;
  final Color dot;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LoopdPressable(
      onTap: onTap,
      label: value == null ? label : '$label, $value',
      pressedScale: 0.99,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Row(
          children: [
            _RowStart(label: label, hint: hint, dot: dot, tint: tint),
            if (value != null)
              Text(
                value!,
                style: LoopdType.small.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
              ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.dot,
    required this.tint,
    required this.value,
    required this.activeColor,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final String? hint;
  final Color dot;
  final Color tint;
  final bool value;
  final Color activeColor;

  /// Null until the feature behind the switch is built: the switch is faded.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 58),
    child: Row(
      children: [
        _RowStart(label: label, hint: hint, dot: dot, tint: tint),
        Opacity(
          opacity: onChanged == null ? 0.4 : 1,
          child: LoopdSwitch(label: label, value: value, activeColor: activeColor, onChanged: onChanged),
        ),
      ],
    ),
  );
}
