import 'package:flutter/material.dart';

import '../../../core/ledger/ledger_types.dart';
import '../../../design_system/components/loopd_button.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'short_dates.dart';

/// Opens Bill due date (mockup `BillDueDay.dc.html`, screen 4e) for [card], or
/// for a card still being added when null. Returns the chosen day, a null
/// day when cleared, or null when closed without saving.
Future<({int? day})?> showBillDueSheet(
  BuildContext context, {
  required LedgerAccount? card,
  required int? day,
  DateTime Function() clock = DateTime.now,
}) => showLoopdSheet<({int? day})>(
  context: context,
  builder: (_) => BillDueSheet(cardName: card?.nickname, day: day, clock: clock),
);

/// "5th of every month".
String billDueText(int day) => '${dayOrdinal(day)} of every month';

/// "5th".
String dayOrdinal(int day) {
  final suffix = switch (day) {
    11 || 12 || 13 => 'th',
    _ => switch (day % 10) {
      1 => 'st',
      2 => 'nd',
      3 => 'rd',
      _ => 'th',
    },
  };
  return '$day$suffix';
}

/// A day from 1 to 31, with the next due date it gives. A shorter month uses
/// its last day. The reminder on the due date comes with Phase 5.
class BillDueSheet extends StatefulWidget {
  const BillDueSheet({required this.cardName, required this.day, this.clock = DateTime.now, super.key});

  final String? cardName;
  final int? day;
  final DateTime Function() clock;

  @override
  State<BillDueSheet> createState() => _BillDueSheetState();
}

class _BillDueSheetState extends State<BillDueSheet> {
  late int? _day = widget.day;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final next = LedgerAccount(
      id: '',
      kind: AccountKind.creditCard,
      nickname: '',
      isDefault: false,
      billDueDay: _day,
    ).nextBillDue(widget.clock());
    final whose = widget.cardName == null ? 'this card’s' : 'your ${widget.cardName}';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          header: true,
          child: Text('Bill due date', style: LoopdType.title.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(height: LoopdSpace.sm),
        Text(
          'The day $whose bill is due every month.',
          style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: LoopdSpace.lg),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1,
          children: [
            for (var day = 1; day <= 31; day++)
              Semantics(
                container: true,
                child: LoopdPressable(
                  onTap: () => setState(() => _day = day),
                  selected: day == _day,
                  label: 'Day $day',
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: day == _day ? c.creditCard : c.surfaceRaised,
                      borderRadius: BorderRadius.circular(LoopdRadius.tile),
                    ),
                    child: Text(
                      '$day',
                      style: LoopdType.body.copyWith(
                        color: day == _day ? c.onAccent : c.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: LoopdSpace.lg),
        Semantics(
          container: true,
          label: 'Next bill due ${next == null ? 'not set' : shortDay(next)}',
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg),
            decoration: BoxDecoration(color: c.creditCardTint, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Expanded(
                  child: Text('Next bill due', style: LoopdType.label.copyWith(color: c.textSecondary)),
                ),
                Text(
                  next == null ? 'Not set' : shortDay(next),
                  style: LoopdType.bodyStrong.copyWith(color: c.creditCard, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: LoopdSpace.md),
        Text(
          'In a shorter month, Loopd uses its last day.',
          style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: LoopdSpace.lg),
        Row(
          children: [
            Expanded(
              child: Semantics(
                container: true,
                child: LoopdButton(
                  label: 'Clear',
                  style: LoopdButtonStyle.outlined,
                  onTap: _day == null ? null : () => setState(() => _day = null),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Semantics(
                container: true,
                child: LoopdButton(label: 'Save', onTap: () => Navigator.of(context).pop((day: _day))),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The "Bill due date" row on the Add card form and on a card's options.
class BillDueRow extends StatelessWidget {
  const BillDueRow({required this.day, required this.onTap, this.bordered = true, super.key});

  final int? day;
  final VoidCallback onTap;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final value = day == null ? 'Optional' : billDueText(day!);
    return Semantics(
      container: true,
      child: LoopdPressable(
        onTap: onTap,
        label: 'Bill due date, $value',
        pressedScale: 1,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: bordered
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.line),
                )
              : null,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Bill due date',
                  style: LoopdType.label.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
                ),
              ),
              Text(
                '$value ›',
                style: LoopdType.body.copyWith(
                  color: day == null ? c.textMuted : c.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
