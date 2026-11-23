import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/ledger/ledger_engine.dart';
import '../../../core/ledger/ledger_types.dart';
import '../../../design_system/components/loopd_button.dart';
import '../../../design_system/components/loopd_error_note.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/components/loopd_switch.dart';
import '../../../design_system/components/loopd_toast.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'bill_due_sheet.dart';

/// Opens Account details or Card details (mockups A5 and A6). Shows a toast
/// with what was done.
Future<void> showAccountDetailsSheet(
  BuildContext context,
  LedgerAccount account, {
  DateTime Function() clock = DateTime.now,
}) async {
  final message = await showLoopdSheet<String>(
    context: context,
    builder: (_) => AccountDetailsSheet(account: account, clock: clock),
  );
  if (message != null && context.mounted) showLoopdToast(context, message);
}

/// The nickname, a card's bill due date, the default and Remove. The bank and
/// the last four digits cannot change, because they link each SMS. Removing
/// asks once more; past expenses stay under the name they were saved with.
class AccountDetailsSheet extends ConsumerStatefulWidget {
  const AccountDetailsSheet({required this.account, this.clock = DateTime.now, super.key});

  final LedgerAccount account;
  final DateTime Function() clock;

  static const nicknameKey = ValueKey('details-nickname');

  @override
  ConsumerState<AccountDetailsSheet> createState() => _AccountDetailsSheetState();
}

class _AccountDetailsSheetState extends ConsumerState<AccountDetailsSheet> {
  late final _nickname = TextEditingController(text: widget.account.nickname);
  late bool _isDefault = widget.account.isDefault;
  late int? _dueDay = widget.account.billDueDay;
  bool _confirmRemove = false;
  bool _saving = false;
  String? _error;

  LedgerAccount get _account => widget.account;
  bool get _isCard => _account.kind == AccountKind.creditCard;
  bool get _changed =>
      _nickname.text.trim() != _account.nickname || _isDefault != _account.isDefault || _dueDay != _account.billDueDay;

  @override
  void initState() {
    super.initState();
    _nickname.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _pickDueDay() async {
    FocusScope.of(context).unfocus();
    final picked = await showBillDueSheet(context, card: _account, day: _dueDay, clock: widget.clock);
    if (picked != null && mounted) setState(() => _dueDay = picked.day);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      await ref
          .read(ledgerEngineProvider)
          .saveAccountDetails(_account.id, nickname: _nickname.text, isDefault: _isDefault, billDueDay: _dueDay);
      if (mounted) Navigator.of(context).pop('Saved changes');
    } on LedgerException {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save. Check the nickname.';
      });
    }
  }

  Future<void> _remove() async {
    await ref.read(ledgerEngineProvider).removeAccount(_account.id);
    if (mounted) Navigator.of(context).pop('Removed ${_account.nickname}');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final code = _account.bankCode;
    if (_confirmRemove) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Remove ${_account.nickname}?', style: LoopdType.title.copyWith(color: c.textPrimary)),
          const SizedBox(height: LoopdSpace.sm),
          Text(
            'Its past expenses stay, under this name. New expenses and SMS can no longer use it.',
            style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: LoopdSpace.xl),
          Row(
            children: [
              Expanded(
                child: LoopdButton(
                  label: 'Keep',
                  style: LoopdButtonStyle.outlined,
                  onTap: () => setState(() => _confirmRemove = false),
                ),
              ),
              const SizedBox(width: LoopdSpace.md),
              Expanded(
                child: LoopdButton(label: 'Remove', accent: c.danger, onTap: _remove),
              ),
            ],
          ),
        ],
      );
    }

    final label = LoopdType.label.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500);
    final divider = Divider(height: 1, thickness: 1, color: c.line);
    Widget row(Widget child) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg),
        child: child,
      ),
    );
    final defaultLabel = _isCard ? 'Default credit card' : 'Default for UPI';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          header: true,
          child: Text(
            _isCard ? 'Card details' : 'Account details',
            style: LoopdType.title.copyWith(color: c.textPrimary),
          ),
        ),
        const SizedBox(height: LoopdSpace.sm),
        Text(
          code == null
              ? 'Not in the bank list, so SMS from this bank are not linked yet.'
              : 'SMS from $code ending ${_account.last4} are linked here.',
          style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: LoopdSpace.lg),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(LoopdRadius.cardLarge),
                    border: Border.all(color: c.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      row(
                        Row(
                          children: [
                            Text('Nickname', style: label),
                            const SizedBox(width: LoopdSpace.md),
                            Expanded(
                              child: TextField(
                                key: AccountDetailsSheet.nicknameKey,
                                controller: _nickname,
                                textAlign: TextAlign.end,
                                textCapitalization: TextCapitalization.words,
                                inputFormatters: [LengthLimitingTextInputFormatter(24)],
                                style: LoopdType.bodyStrong.copyWith(color: c.textPrimary, fontSize: 16),
                                decoration: const InputDecoration.collapsed(hintText: ''),
                              ),
                            ),
                          ],
                        ),
                      ),
                      divider,
                      row(
                        Row(
                          children: [
                            Text('Bank', style: label),
                            const SizedBox(width: LoopdSpace.md),
                            Expanded(
                              child: Text(
                                _account.bankName ?? 'Not set',
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: LoopdType.body.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                      divider,
                      row(
                        Row(
                          children: [
                            Expanded(child: Text('Last four digits', style: label)),
                            Text(
                              _account.last4 ?? '',
                              style: LoopdType.code.copyWith(
                                color: c.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      divider,
                      if (_isCard) ...[BillDueRow(day: _dueDay, onTap: _pickDueDay, bordered: false), divider],
                      row(
                        Row(
                          children: [
                            Expanded(child: Text(defaultLabel, style: label)),
                            LoopdSwitch(
                              label: defaultLabel,
                              value: _isDefault,
                              activeColor: _isCard ? c.creditCard : c.money,
                              onChanged: (value) => setState(() => _isDefault = value),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null) ...[const SizedBox(height: LoopdSpace.md), LoopdErrorNote(_error!)],
                const SizedBox(height: LoopdSpace.lg),
                Semantics(
                  container: true,
                  child: LoopdButton(
                    label: _isCard ? 'Remove card' : 'Remove account',
                    style: LoopdButtonStyle.danger,
                    onTap: () {
                      FocusScope.of(context).unfocus();
                      setState(() => _confirmRemove = true);
                    },
                  ),
                ),
                const SizedBox(height: LoopdSpace.md),
              ],
            ),
          ),
        ),
        Semantics(
          container: true,
          child: LoopdButton(
            label: 'Save changes',
            onTap: _changed && _nickname.text.trim().isNotEmpty && !_saving ? _save : null,
          ),
        ),
      ],
    );
  }
}
