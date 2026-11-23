import 'package:flutter/material.dart';

import '../../../core/ledger/ledger_types.dart';
import '../../../core/ledger/rupees.dart';
import '../../../design_system/components/loopd_button.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'when_text.dart';

/// One refund as the delete question lists it, with where the money went.
typedef RefundLine = ({RefundRecord refund, String accountName});

/// Asks before deleting a purchase that has refunds, and lists them (proposal
/// section 13: they go only together, as an explicit choice). True for
/// Delete all.
Future<bool> showDeleteRefundedSheet(
  BuildContext context, {
  required String name,
  required int amountPaise,
  required List<RefundLine> refunds,
  required DateTime now,
}) async =>
    await showLoopdSheet<bool>(
      context: context,
      builder: (_) => DeleteRefundedSheet(name: name, amountPaise: amountPaise, refunds: refunds, now: now),
    ) ??
    false;

class DeleteRefundedSheet extends StatelessWidget {
  const DeleteRefundedSheet({
    required this.name,
    required this.amountPaise,
    required this.refunds,
    required this.now,
    super.key,
  });

  final String name;
  final int amountPaise;
  final List<RefundLine> refunds;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = refunds.length == 1 ? '1 refund' : '${refunds.length} refunds';
    final them = refunds.length == 1 ? 'It will' : 'They will';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          header: true,
          child: Text('Delete this expense?', style: LoopdType.title.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(height: LoopdSpace.sm),
        Text(
          '$name, ${formatRupees(amountPaise)}, has $count. $them be deleted with it.',
          style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: LoopdSpace.lg),
        Flexible(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LoopdRadius.cardLarge),
              border: Border.all(color: c.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final (i, line) in refunds.indexed) ...[
                    if (i > 0) Divider(height: 1, thickness: 1, color: c.line),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: LoopdSpace.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Refunded to ${line.accountName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: LoopdType.label.copyWith(color: c.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  whenText(line.refund.occurredAt, now: now),
                                  style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: LoopdSpace.sm),
                          Text(
                            '+${formatRupees(line.refund.amountPaise)}',
                            style: LoopdType.amount.copyWith(color: c.money),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: LoopdSpace.lg),
        Row(
          children: [
            Expanded(
              child: Semantics(
                container: true,
                child: LoopdButton(
                  label: 'Keep',
                  style: LoopdButtonStyle.outlined,
                  onTap: () => Navigator.of(context).pop(false),
                ),
              ),
            ),
            const SizedBox(width: LoopdSpace.md),
            Expanded(
              child: Semantics(
                container: true,
                child: LoopdButton(label: 'Delete all', accent: c.danger, onTap: () => Navigator.of(context).pop(true)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
