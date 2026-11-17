import 'package:flutter/material.dart';

import '../../../design_system/components/loopd_button.dart';
import '../../../design_system/components/loopd_round_button.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/components/loopd_toast.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';

/// Opens the capture sheet, reachable from every tab.
///
/// Phase 1 builds its shell, drawn to the mockup (`Capture.dc.html`): one
/// input, five shortcuts and three ready questions. Understanding what is
/// typed (the offline assistant's rules, never called AI) arrives in
/// Phase 9; the shortcuts open their forms as those are built.
Future<void> showCaptureSheet(BuildContext context) =>
    showLoopdSheet<void>(context: context, builder: (_) => const _CaptureSheet());

class _CaptureSheet extends StatefulWidget {
  const _CaptureSheet();

  @override
  State<_CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends State<_CaptureSheet> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    void soon(String what, int phase) => showLoopdToast(context, '$what is built in Phase $phase');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text('Add anything', style: LoopdType.title.copyWith(color: c.textPrimary)),
                ),
              ),
              LoopdRoundButton(
                icon: Icons.close_rounded,
                label: 'Close',
                size: 40,
                background: c.surfaceRaised,
                foreground: c.textPrimary,
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _CommandBox(controller: _input),
          const SizedBox(height: LoopdSpace.md),
          // The save button from the mockup. It works once typed text is
          // understood (Phase 9); until then it is shown faded.
          const LoopdButton(label: 'Save', icon: Icons.check_rounded, onTap: null),
          const SizedBox(height: 18),
          Text('Or start from', style: LoopdType.caption.copyWith(color: c.textMuted)),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final (label, color, icon, phase) in [
                ('Expense', c.money, Icons.currency_rupee_rounded, 2),
                ('Lent', c.lending, Icons.handshake_outlined, 4),
                ('Trip', c.travel, Icons.confirmation_number_outlined, 5),
                ('Note', c.notes, Icons.sticky_note_2_outlined, 6),
                ('Task', c.task, Icons.check_circle_outline_rounded, 6),
              ])
                Expanded(
                  child: _Shortcut(label: label, color: color, icon: icon, onTap: () => soon(label, phase)),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Ask', style: LoopdType.caption.copyWith(color: c.textMuted)),
          const SizedBox(height: LoopdSpace.sm),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LoopdRadius.card),
              border: Border.all(color: c.line),
            ),
            child: Column(
              children: [
                for (final (index, (question, dot)) in [
                  ('Who owes me?', c.lending),
                  ('Next trip', c.travel),
                  ('Spent this month', c.money),
                ].indexed) ...[
                  if (index > 0) Divider(height: 1, thickness: 1, color: c.line),
                  _AskRow(question: question, dot: dot, onTap: () => soon('Answers', 9)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The one input, on a raised surface with a hairline border that will take
/// the colour of what was understood (Phase 9).
class _CommandBox extends StatelessWidget {
  const _CommandBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(LoopdRadius.section),
        // Green as in the mockup, which shows an expense being typed. From
        // Phase 9 it takes the colour of what was understood.
        border: Border.all(color: c.money, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_outlined, size: 20, color: c.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: LoopdType.heading.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
                  cursorColor: c.textPrimary,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration.collapsed(
                    hintText: 'spent 250 on lunch hdfc upi',
                    hintStyle: LoopdType.heading.copyWith(color: c.textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: LoopdSpace.md),
          Text(
            'Type a payment, a loan, a task or a question.',
            style: LoopdType.small.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.label, required this.color, required this.icon, required this.onTap});

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: 'New $label',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 22, color: c.onAccent),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: LoopdType.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}

class _AskRow extends StatelessWidget {
  const _AskRow({required this.question, required this.dot, required this.onTap});

  final String question;
  final Color dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: question,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: LoopdSpace.md),
                Expanded(
                  child: Text(question, style: LoopdType.body.copyWith(color: c.textPrimary)),
                ),
                Icon(Icons.chevron_right_rounded, size: 20, color: c.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
