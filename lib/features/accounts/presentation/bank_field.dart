import 'package:flutter/material.dart';

import '../../../core/ledger/banks.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_motion.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';

/// The search field with its dropdown: typing filters the list and
/// highlights the match; a missing bank can be added by name.
class BankField extends StatelessWidget {
  const BankField({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.open,
    required this.accent,
    required this.chosen,
    required this.isCard,
    required this.onChanged,
    required this.onToggle,
    required this.onPick,
    required this.onPickTyped,
    super.key,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool open;
  final Color accent;
  final Bank? chosen;
  final bool isCard;
  final VoidCallback onChanged;
  final VoidCallback onToggle;
  final ValueChanged<Bank> onPick;
  final VoidCallback onPickTyped;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final query = controller.text.trim();
    final lower = query.toLowerCase();
    final options = banks.where((bank) => isCard || !bank.cardsOnly);
    final results = chosen != null || lower.isEmpty
        ? options.toList()
        : options.where((bank) => bank.name.toLowerCase().contains(lower)).toList();
    final exact = results.any((bank) => bank.name.toLowerCase() == lower);
    final offerTyped = query.isNotEmpty && chosen == null && !exact && results.length < 3;
    return AnimatedContainer(
      duration: LoopdMotion.of(context).quick,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: open ? accent : const Color(0x00000000), width: 1.5),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search_rounded, size: 18, color: c.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    key: fieldKey,
                    controller: controller,
                    focusNode: focusNode,
                    onChanged: (_) => onChanged(),
                    textCapitalization: TextCapitalization.words,
                    autocorrect: false,
                    style: LoopdType.bodyStrong.copyWith(color: c.textPrimary, fontSize: 16),
                    cursorColor: accent,
                    decoration: InputDecoration.collapsed(
                      hintText: 'Search your bank',
                      hintStyle: LoopdType.bodyStrong.copyWith(color: c.textMuted, fontSize: 16),
                    ),
                  ),
                ),
                LoopdPressable(
                  onTap: onToggle,
                  label: open ? 'Hide banks' : 'Show all banks',
                  child: SizedBox(
                    width: LoopdSize.minTouch,
                    height: LoopdSize.minTouch,
                    child: AnimatedRotation(
                      turns: open ? 0.5 : 0,
                      duration: LoopdMotion.of(context).quick,
                      child: Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: c.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: LoopdSpace.xs),
              ],
            ),
          ),
          if (open) ...[
            Divider(height: 1, thickness: 1, color: c.line),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 232),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final bank in results)
                    _BankOption(
                      bank: bank,
                      highlight: chosen == null ? lower : '',
                      accent: accent,
                      onTap: () => onPick(bank),
                    ),
                  if (offerTyped) _TypedOption(name: query, accent: accent, onTap: onPickTyped),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BankOption extends StatelessWidget {
  const _BankOption({required this.bank, required this.highlight, required this.accent, required this.onTap});

  final Bank bank;

  /// The typed text, shown in bold where it matches.
  final String highlight;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = LoopdType.body.copyWith(color: c.textPrimary, fontWeight: FontWeight.w500);
    final at = highlight.isEmpty ? -1 : bank.name.toLowerCase().indexOf(highlight);
    final capitals = bank.name.replaceAll(RegExp('[^A-Z]'), '');
    final initials = (capitals.length >= 2 ? capitals : bank.name).substring(0, 2).toUpperCase();
    return LoopdPressable(
      onTap: onTap,
      label: bank.name,
      pressedScale: 0.99,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Color(bank.colour), borderRadius: BorderRadius.circular(9)),
              child: Text(
                initials,
                style: LoopdType.micro.copyWith(color: const Color(0xFFFFFFFF), fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: LoopdSpace.md),
            Expanded(
              child: Text.rich(
                at < 0
                    ? TextSpan(text: bank.name)
                    : TextSpan(
                        children: [
                          TextSpan(text: bank.name.substring(0, at)),
                          TextSpan(
                            text: bank.name.substring(at, at + highlight.length),
                            style: TextStyle(color: accent, fontWeight: FontWeight.w800),
                          ),
                          TextSpan(text: bank.name.substring(at + highlight.length)),
                        ],
                      ),
                style: style,
              ),
            ),
            Text(bank.code, style: LoopdType.code.copyWith(color: c.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// The last row of the list when the bank is missing: a clear action in the
/// sheet's colour, saying what adding it means.
class _TypedOption extends StatelessWidget {
  const _TypedOption({required this.name, required this.accent, required this.onTap});

  final String name;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LoopdPressable(
      onTap: onTap,
      label: 'Add $name as a new bank',
      pressedScale: 0.99,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: accent.withValues(alpha: 0.1),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(9)),
              child: Icon(Icons.add_rounded, size: 18, color: c.onAccent),
            ),
            const SizedBox(width: LoopdSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Add '),
                        TextSpan(
                          text: '“$name”',
                          style: TextStyle(color: c.textPrimary, fontWeight: FontWeight.w800),
                        ),
                        const TextSpan(text: ' as a new bank'),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: LoopdType.label.copyWith(color: c.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: LoopdSpace.xxs),
                  Text(
                    'Not in the list yet',
                    style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
