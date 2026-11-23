import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/ledger/ledger_engine.dart';
import '../../../core/ledger/ledger_types.dart';
import '../../../core/ledger/rupees.dart';
import '../../../design_system/components/loopd_button.dart';
import '../../../design_system/components/loopd_error_note.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'amount_input.dart';
import 'expense_sheet.dart' show ExpenseDone, showDoneToast;
import 'form_parts.dart';
import 'providers/expense_providers.dart';
import 'spending_parts.dart' show categoryLook;
import 'when_text.dart';

/// Opens the refund form for the purchase [expenseId] (mockup
/// `EntryRefund.dc.html`, screens A10 and A11): new, or with [refundId] to
/// edit or delete that refund. After a save or a delete, a toast offers Undo.
Future<void> showRefundSheet(
  BuildContext context, {
  required String expenseId,
  String? refundId,
  DateTime Function() clock = DateTime.now,
}) async {
  final ledger = ProviderScope.containerOf(context, listen: false).read(ledgerEngineProvider);
  final done = await showLoopdSheet<ExpenseDone>(
    context: context,
    builder: (_) => RefundSheet(expenseId: expenseId, refundId: refundId, clock: clock),
  );
  if (done != null && context.mounted) showDoneToast(context, ledger, done);
}

/// Money back for one purchase. It lowers the month of the purchase, and goes
/// back to the account or card the purchase was paid from: Loopd keeps no
/// balances, so where it landed changes no total (owner, 23 Nov 2026).
class RefundSheet extends ConsumerStatefulWidget {
  const RefundSheet({required this.expenseId, this.refundId, this.clock = DateTime.now, super.key});

  final String expenseId;
  final String? refundId;
  final DateTime Function() clock;

  static const amountFieldKey = ValueKey('refund-amount');
  static const noteFieldKey = ValueKey('refund-note');
  static const whenKey = ValueKey('refund-when');

  @override
  ConsumerState<RefundSheet> createState() => _RefundSheetState();
}

class _RefundSheetState extends ConsumerState<RefundSheet> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late DateTime _when = _minute(widget.clock());

  ExpenseRecord? _expense;
  RefundRecord? _refund;

  /// What other refunds of this purchase already returned.
  int _refundedBefore = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.refundId != null;

  static DateTime _minute(DateTime at) => DateTime(at.year, at.month, at.day, at.hour, at.minute);

  @override
  void initState() {
    super.initState();
    for (final field in [_amount, _note]) {
      field.addListener(() => setState(() => _error = null));
    }
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final ledger = ref.read(ledgerEngineProvider);
    final expense = await ledger.getExpense(widget.expenseId);
    final before = expense == null ? 0 : await ledger.refundedPaise(expense.id, excluding: widget.refundId);
    final refund = widget.refundId == null ? null : await ledger.getRefund(widget.refundId!);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (expense == null) {
        _error = 'This purchase no longer exists.';
        return;
      }
      if (_editing && refund == null) {
        _error = 'This refund no longer exists.';
        return;
      }
      _expense = expense;
      _refund = refund;
      _refundedBefore = before;
      if (refund != null) {
        _amount.text = amountFieldText(refund.amountPaise);
        _note.text = refund.note ?? '';
        _when = refund.occurredAt;
      } else if (expense.amountPaise > before) {
        _amount.text = amountFieldText(expense.amountPaise - before);
      }
      _error = null;
    });
  }

  Future<void> _pickWhen() async {
    FocusScope.of(context).unfocus();
    final now = widget.clock();
    final date = await showDatePicker(
      context: context,
      initialDate: _when.isAfter(now) ? now : _when,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when));
    if (time == null || !mounted) return;
    setState(() {
      _when = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _error = null;
    });
  }

  Future<void> _save(int amountPaise) async {
    final ledger = ref.read(ledgerEngineProvider);
    final expense = _expense!;
    final refund = _refund;
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final amount = formatRupees(amountPaise);
    setState(() => _saving = true);
    try {
      final ExpenseDone done;
      if (refund == null) {
        final id = await ledger.recordRefund(
          originalId: expense.id,
          amountPaise: amountPaise,
          method: expense.method,
          destinationAccountId: expense.fundingAccountId,
          occurredAt: _when,
          note: note,
        );
        done = ExpenseDone(id: id, revision: 1, message: 'Refund of $amount saved', undoneMessage: 'Removed $amount');
      } else {
        await ledger.editRefund(
          refund.id,
          amountPaise: amountPaise,
          method: refund.method,
          destinationAccountId: refund.destinationAccountId,
          occurredAt: _when,
          note: note,
        );
        done = ExpenseDone(
          id: refund.id,
          revision: refund.revision + 1,
          message: 'Saved changes',
          undoneMessage: 'Change undone',
        );
      }
      if (mounted) Navigator.of(context).pop(done);
    } on LedgerException catch (error) {
      _fail(error);
    }
  }

  Future<void> _delete() async {
    final refund = _refund!;
    final amount = formatRupees(refund.amountPaise);
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await ref.read(ledgerEngineProvider).delete(refund.id);
      if (!mounted) return;
      Navigator.of(context).pop(
        ExpenseDone(
          id: refund.id,
          revision: refund.revision + 1,
          message: 'Deleted $amount',
          undoneMessage: 'Brought back $amount',
        ),
      );
    } on LedgerException catch (error) {
      _fail(error);
    }
  }

  void _fail(LedgerException error) {
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = switch (error.failure) {
        LedgerFailure.refundExceedsOriginal => 'The refunds would add up to more than the purchase.',
        LedgerFailure.refundWithoutOriginal => 'This purchase no longer exists.',
        LedgerFailure.notFound => 'This refund no longer exists.',
        _ => 'Could not save. Check the amount.',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final categories = ref.watch(expenseCategoriesProvider);
    final expense = _expense;
    final ready = !_loading && expense != null && categories.hasValue && (!_editing || _refund != null);
    if (!ready) {
      return SizedBox(
        height: 320,
        child: Align(alignment: Alignment.topCenter, child: _error == null ? null : LoopdErrorNote(_error!)),
      );
    }

    final amountPaise = parseRupees(_amount.text);
    final validAmount = amountPaise != null && amountPaise > 0;
    final left = expense.amountPaise - _refundedBefore;
    final tooMuch = validAmount && amountPaise > left;
    final future = _when.isAfter(widget.clock());
    final message = future ? 'That time is still to come. Pick a time that has passed.' : _error;
    final canSave = validAmount && !tooMuch && !future && !_saving;
    final name = expense.merchant ?? categoryLook(expense.categoryId, categories.requireValue).name;
    final day = whenText(expense.occurredAt, now: DateTime(expense.occurredAt.year + 1)).split(',').first;
    final hint = left <= 0
        ? 'Nothing is left to refund'
        : tooMuch
        ? 'More than the ${formatRupees(left)} left to refund'
        : 'Up to ${formatRupees(left)}';
    final saveLabel = _editing ? 'Save changes' : 'Save refund${validAmount ? ' ${formatRupees(amountPaise)}' : ''}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          header: true,
          child: Text(_editing ? 'Edit refund' : 'Add refund', style: LoopdType.title.copyWith(color: c.textPrimary)),
        ),
        const SizedBox(height: LoopdSpace.sm),
        Text(
          '$name · ${formatRupees(expense.amountPaise)} · ${day.replaceFirst(RegExp(r' \d{4}$'), '')}',
          style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 18),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AmountField(
                  fieldKey: RefundSheet.amountFieldKey,
                  controller: _amount,
                  accent: c.money,
                  autofocus: false,
                  below: Text(
                    hint,
                    style: LoopdType.small.copyWith(
                      color: tooMuch || left <= 0 ? c.danger : c.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                DetailsCard(
                  note: _note,
                  noteKey: RefundSheet.noteFieldKey,
                  whenKey: RefundSheet.whenKey,
                  whenLabel: whenText(_when, now: widget.clock()),
                  onWhen: _pickWhen,
                ),
                if (_editing) ...[
                  const SizedBox(height: 18),
                  Semantics(
                    container: true,
                    child: LoopdButton(
                      label: 'Delete refund',
                      style: LoopdButtonStyle.danger,
                      onTap: _saving ? null : _delete,
                    ),
                  ),
                ],
                if (message != null) ...[const SizedBox(height: LoopdSpace.md), LoopdErrorNote(message)],
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
        Semantics(
          container: true,
          child: LoopdButton(label: saveLabel, onTap: canSave ? () => _save(amountPaise) : null),
        ),
      ],
    );
  }
}
