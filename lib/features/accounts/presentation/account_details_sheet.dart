import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/ledger/banks.dart';
import '../../../core/ledger/ledger_engine.dart';
import '../../../core/ledger/ledger_types.dart';
import '../../../design_system/components/loopd_button.dart';
import '../../../design_system/components/loopd_error_note.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/components/loopd_switch.dart';
import '../../../design_system/components/loopd_toast.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'bank_field.dart';
import 'bill_due_sheet.dart';
import 'providers/accounts_providers.dart';

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

/// The nickname, bank, last four digits, a card's bill due date, the default
/// and Remove. Past expenses stay on this account and show the new details.
/// Digits already used by another account of this kind cannot be saved,
/// because they link each SMS. Removing asks once more.
class AccountDetailsSheet extends ConsumerStatefulWidget {
  const AccountDetailsSheet({required this.account, this.clock = DateTime.now, super.key});

  final LedgerAccount account;
  final DateTime Function() clock;

  static const nicknameKey = ValueKey('details-nickname');
  static const bankRowKey = ValueKey('details-bank');
  static const bankSearchKey = ValueKey('details-bank-search');
  static const last4Key = ValueKey('details-last4');

  @override
  ConsumerState<AccountDetailsSheet> createState() => _AccountDetailsSheetState();
}

class _AccountDetailsSheetState extends ConsumerState<AccountDetailsSheet> {
  late final _nickname = TextEditingController(text: widget.account.nickname);
  late final _last4 = TextEditingController(text: widget.account.last4 ?? '');
  final _bankQuery = TextEditingController();
  final _bankFocus = FocusNode();
  late String? _bankName = widget.account.bankName;
  late String? _bankCode = widget.account.bankCode;
  bool _bankOpen = false;
  late bool _isDefault = widget.account.isDefault;
  late int? _dueDay = widget.account.billDueDay;
  bool _confirmRemove = false;
  bool _saving = false;
  String? _error;

  LedgerAccount get _account => widget.account;
  bool get _isCard => _account.kind == AccountKind.creditCard;
  bool get _bankChanged => _bankName != _account.bankName || _bankCode != _account.bankCode;
  bool get _digitsChanged => _last4.text != (_account.last4 ?? '');
  bool get _digitsComplete => _last4.text.length == 4 || (_last4.text.isEmpty && _account.last4 == null);
  bool get _changed =>
      _nickname.text.trim() != _account.nickname ||
      _isDefault != _account.isDefault ||
      _dueDay != _account.billDueDay ||
      _bankChanged ||
      _digitsChanged;

  @override
  void initState() {
    super.initState();
    for (final field in [_nickname, _last4]) {
      field.addListener(() => setState(() => _error = null));
    }
  }

  @override
  void dispose() {
    _nickname.dispose();
    _last4.dispose();
    _bankQuery.dispose();
    _bankFocus.dispose();
    super.dispose();
  }

  void _openBanks() {
    FocusScope.of(context).unfocus();
    setState(() => _bankOpen = true);
  }

  /// Closes the list. The bank stays as it was unless one was picked.
  void _closeBanks() {
    _bankFocus.unfocus();
    _bankQuery.clear();
    setState(() => _bankOpen = false);
  }

  void _setBank(String name, String? code) {
    _bankName = name;
    _bankCode = code;
    _error = null;
    _closeBanks();
  }

  /// Another account of this kind that already has [last4], if any.
  LedgerAccount? _takenBy(String last4) {
    if (last4.length != 4) return null;
    final saved = ref.watch(accountsOfKindProvider(_account.kind)).value ?? const <LedgerAccount>[];
    for (final other in saved) {
      if (other.id != _account.id && other.last4 == last4) return other;
    }
    return null;
  }

  String _takenMessage(String last4, LedgerAccount? owner) {
    final kind = _isCard ? 'card' : 'bank account';
    return owner == null
        ? 'A $kind ending ••$last4 is already saved.'
        : '${owner.nickname} already ends ••$last4. Each $kind needs its own last four digits.';
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
          .saveAccountDetails(
            _account.id,
            nickname: _nickname.text,
            isDefault: _isDefault,
            billDueDay: _dueDay,
            bank: _bankChanged && _bankName != null ? (name: _bankName!, code: _bankCode) : null,
            last4: _digitsChanged ? _last4.text : null,
          );
      if (mounted) Navigator.of(context).pop('Saved changes');
    } on LedgerException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.failure == LedgerFailure.duplicateAccount
            ? _takenMessage(_last4.text, null)
            : 'Could not save. Check the nickname, bank and digits.';
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
    final code = _bankCode;
    final digits = _last4.text;
    final taken = _takenBy(digits);
    final error = taken != null ? _takenMessage(digits, taken) : _error;
    final accent = _isCard ? c.creditCard : c.money;
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
              : digits.length == 4
              ? 'SMS from $code ending $digits are linked here.'
              : 'Enter the last four digits to link SMS from $code.',
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
                      if (_bankOpen)
                        Padding(
                          padding: const EdgeInsets.all(LoopdSpace.sm),
                          child: BankField(
                            fieldKey: AccountDetailsSheet.bankSearchKey,
                            controller: _bankQuery,
                            focusNode: _bankFocus,
                            open: true,
                            accent: accent,
                            chosen: null,
                            isCard: _isCard,
                            onChanged: () => setState(() {}),
                            onToggle: _closeBanks,
                            onPick: (bank) => _setBank(bank.name, bank.code),
                            onPickTyped: () => _setBank(_bankQuery.text.trim(), bankNamed(_bankQuery.text)?.code),
                          ),
                        )
                      else
                        LoopdPressable(
                          key: AccountDetailsSheet.bankRowKey,
                          onTap: _openBanks,
                          label: 'Bank, ${_bankName ?? 'not set'}. Change bank',
                          pressedScale: 1,
                          child: row(
                            Row(
                              children: [
                                Text('Bank', style: label),
                                const SizedBox(width: LoopdSpace.md),
                                Expanded(
                                  child: Text(
                                    _bankName ?? 'Not set',
                                    textAlign: TextAlign.end,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: LoopdType.body.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: LoopdSpace.xs),
                                Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: c.textMuted),
                              ],
                            ),
                          ),
                        ),
                      divider,
                      row(
                        Row(
                          children: [
                            Expanded(child: Text('Last four digits', style: label)),
                            SizedBox(
                              width: 96,
                              child: TextField(
                                key: AccountDetailsSheet.last4Key,
                                controller: _last4,
                                textAlign: TextAlign.end,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                style: LoopdType.code.copyWith(
                                  color: c.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 3,
                                ),
                                cursorColor: accent,
                                decoration: const InputDecoration.collapsed(hintText: '0000'),
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
                              activeColor: accent,
                              onChanged: (value) => setState(() => _isDefault = value),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (error != null) ...[const SizedBox(height: LoopdSpace.md), LoopdErrorNote(error)],
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
            onTap: _changed && _nickname.text.trim().isNotEmpty && _digitsComplete && taken == null && !_saving
                ? _save
                : null,
          ),
        ),
      ],
    );
  }
}
