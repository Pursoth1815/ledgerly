import 'package:flutter/material.dart';

import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_motion.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'amount_input.dart';

// The parts the money forms share: the expense form, and the form for money
// in, moves, card bills and refunds (mockups `AddExpense.dc.html` and
// `MoneyMove.dc.html`).

/// A small grey heading over a part of a money form, such as "Paid with".
class FormSectionTitle extends StatelessWidget {
  const FormSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: LoopdType.small.copyWith(color: context.colors.textMuted)),
  );
}

/// The big centred amount, with the ₹ in the method's colour.
class AmountField extends StatelessWidget {
  const AmountField({
    required this.controller,
    required this.accent,
    required this.autofocus,
    this.fieldKey,
    this.below,
    super.key,
  });

  /// Finds the field in tests.
  final Key? fieldKey;

  /// A line under the amount, such as "Up to ₹1,500".
  final Widget? below;
  final TextEditingController controller;
  final Color accent;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const style = TextStyle(
      fontFamily: LoopdType.sans,
      fontSize: 48,
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
      height: 1.15,
      fontFeatures: [FontFeature.tabularFigures()],
    );
    return Column(
      children: [
        Text(
          'Amount',
          style: LoopdType.small.copyWith(color: c.textMuted, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: LoopdSpace.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            AnimatedDefaultTextStyle(
              duration: LoopdMotion.of(context).standard,
              style: style.copyWith(fontSize: 32, fontWeight: FontWeight.w700, color: accent),
              child: const Text('₹'),
            ),
            const SizedBox(width: LoopdSpace.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 40, maxWidth: 280),
              child: IntrinsicWidth(
                child: TextField(
                  key: fieldKey,
                  controller: controller,
                  autofocus: autofocus,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: const [RupeeInputFormatter()],
                  textAlign: TextAlign.center,
                  cursorColor: accent,
                  style: style.copyWith(color: c.textPrimary),
                  decoration: InputDecoration.collapsed(
                    hintText: '0',
                    hintStyle: style.copyWith(color: c.textMuted),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (below != null) ...[const SizedBox(height: LoopdSpace.xs), below!],
      ],
    );
  }
}

/// An optional name (such as Paid to), Date and time, and Note, in one
/// outlined card.
class DetailsCard extends StatelessWidget {
  const DetailsCard({
    required this.note,
    required this.whenLabel,
    required this.onWhen,
    this.name,
    this.nameLabel = '',
    this.nameHint = '',
    this.nameKey,
    this.noteKey,
    this.whenKey,
    this.whenTitle = 'Date and time',
    super.key,
  });

  /// The date row's label, such as "Paid on" for a card bill.
  final String whenTitle;

  /// The name field, such as Paid to; left out when null.
  final TextEditingController? name;
  final String nameLabel;
  final String nameHint;
  final Key? nameKey;
  final Key? noteKey;
  final Key? whenKey;
  final TextEditingController note;
  final String whenLabel;
  final VoidCallback onWhen;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final divider = Divider(height: 1, thickness: 1, color: c.line);
    final rowLabel = LoopdType.label.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500);
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(LoopdRadius.cardLarge),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (name != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(LoopdSpace.lg, 14, LoopdSpace.lg, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nameLabel, style: LoopdType.caption.copyWith(color: c.textMuted)),
                  const SizedBox(height: LoopdSpace.xs),
                  TextField(
                    key: nameKey,
                    controller: name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    style: LoopdType.heading.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
                    decoration: InputDecoration.collapsed(
                      hintText: nameHint,
                      hintStyle: LoopdType.heading.copyWith(color: c.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            divider,
          ],
          LoopdPressable(
            key: whenKey,
            onTap: onWhen,
            label: '$whenTitle, $whenLabel',
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 54),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg),
                child: Row(
                  children: [
                    Expanded(child: Text(whenTitle, style: rowLabel)),
                    Text(
                      '$whenLabel ›',
                      style: LoopdType.body.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          divider,
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 54),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg),
              child: Row(
                children: [
                  Text('Note', style: rowLabel),
                  const SizedBox(width: LoopdSpace.md),
                  Expanded(
                    child: TextField(
                      key: noteKey,
                      controller: note,
                      textAlign: TextAlign.right,
                      textCapitalization: TextCapitalization.sentences,
                      style: LoopdType.body.copyWith(color: c.textPrimary),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Add a note',
                        hintStyle: LoopdType.body.copyWith(color: c.textMuted),
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
