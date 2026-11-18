import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/ledger/ledger_engine.dart';
import '../../../core/ledger/ledger_types.dart';
import '../../../core/ledger/rupees.dart';
import '../../../design_system/components/loopd_button.dart';
import '../../../design_system/components/loopd_dashed_button.dart';
import '../../../design_system/components/loopd_error_note.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/components/loopd_round_button.dart';
import '../../../design_system/components/loopd_segmented.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/components/loopd_source_strip.dart';
import '../../../design_system/components/loopd_toast.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_motion.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import '../../accounts/accounts.dart';
import 'amount_input.dart';
import 'category_sheet.dart';
import 'providers/expense_providers.dart';
import 'when_text.dart';

/// Opens a form for a bank account or card from inside the expense form,
/// when there is none yet. `app/` passes it in, because adding an account
/// belongs to Accounts and cards (architecture rule 3).
typedef AddAccountAction = Future<void> Function(BuildContext context, AccountKind kind);

/// Opens the expense form as a tall sheet (mockup `AddExpense.dc.html`,
/// screens 3, 3b and 3c; owner, 18 Nov 2026: a sheet, not a page). With no
/// [expenseId] it adds an expense; with one it edits that expense and offers
/// Delete. After a save or a delete, a toast offers Undo.
Future<void> showExpenseSheet(
  BuildContext context, {
  String? expenseId,
  AddAccountAction? onAddAccount,
  DateTime Function() clock = DateTime.now,
}) async {
  final ledger = ProviderScope.containerOf(context, listen: false).read(ledgerEngineProvider);
  final done = await showLoopdSheet<ExpenseDone>(
    context: context,
    tall: true,
    builder: (_) => ExpenseSheet(expenseId: expenseId, onAddAccount: onAddAccount, clock: clock),
  );
  if (done == null || !context.mounted) return;
  showLoopdToast(
    context,
    done.message,
    action: 'Undo',
    onAction: () async {
      String result;
      try {
        await ledger.undo(done.id, expectedRevision: done.revision);
        result = done.undoneMessage;
      } on LedgerException catch (error) {
        result = error.failure == LedgerFailure.changedSince
            ? 'It has changed since, so it cannot be undone'
            : 'Could not undo that';
      }
      if (context.mounted) showLoopdToast(context, result);
    },
  );
}

/// What the sheet did, for the toast and its Undo: the expense, the revision
/// the change made, and what to say before and after an undo.
class ExpenseDone {
  const ExpenseDone({required this.id, required this.revision, required this.message, required this.undoneMessage});

  final String id;
  final int revision;
  final String message;
  final String undoneMessage;
}

/// The expense form: the amount, who was paid, when, a note, the method
/// (UPI, Credit Card or Cash) with its account or card, and the category,
/// with one green Save button. One widget adds and edits; the Review Inbox
/// will use it too (Phase 3).
///
/// Nothing is drawn until every list has loaded, so the form never fills in
/// in steps.
class ExpenseSheet extends ConsumerStatefulWidget {
  const ExpenseSheet({this.expenseId, this.onAddAccount, this.clock = DateTime.now, super.key});

  final String? expenseId;
  final AddAccountAction? onAddAccount;
  final DateTime Function() clock;

  static const amountFieldKey = ValueKey('expense-amount');
  static const merchantFieldKey = ValueKey('expense-merchant');
  static const noteFieldKey = ValueKey('expense-note');
  static const whenKey = ValueKey('expense-when');
  static const formKey = ValueKey('expense-form');

  @override
  ConsumerState<ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<ExpenseSheet> {
  final _amount = TextEditingController();
  final _merchant = TextEditingController();
  final _note = TextEditingController();

  late DateTime _when = _minute(widget.clock());
  PaymentMethod _method = PaymentMethod.upi;

  /// The account or card picked by hand; null means "the default".
  String? _accountId;
  String? _categoryId;

  /// The expense being edited, once loaded.
  ExpenseRecord? _original;

  /// Its account or card when that has been removed since, so it can still
  /// be shown and kept.
  LedgerAccount? _removedAccount;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.expenseId != null;

  static DateTime _minute(DateTime at) => DateTime(at.year, at.month, at.day, at.hour, at.minute);

  @override
  void initState() {
    super.initState();
    for (final field in [_amount, _merchant, _note]) {
      field.addListener(() => setState(() => _error = null));
    }
    if (_editing) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final ledger = ref.read(ledgerEngineProvider);
    final expense = await ledger.getExpense(widget.expenseId!);
    final account = expense == null ? null : await ledger.getAccount(expense.fundingAccountId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (expense == null) {
        _error = 'This expense no longer exists.';
        return;
      }
      _original = expense;
      _amount.text = amountFieldText(expense.amountPaise);
      _merchant.text = expense.merchant ?? '';
      _note.text = expense.note ?? '';
      _when = expense.occurredAt;
      _method = expense.method.shownAs;
      _accountId = expense.fundingAccountId;
      _categoryId = expense.categoryId;
      _error = null;
      if (account != null && account.kind != AccountKind.cash) {
        _removedAccount = account; // kept only if it is missing from the live list
      }
    });
  }

  /// Holds the focus while no field should have it, such as on the way to
  /// and back from New category, so returning does not reopen the number
  /// pad on the amount.
  final _restingFocus = FocusNode(debugLabel: 'expense-resting', skipTraversal: true);

  @override
  void dispose() {
    _restingFocus.dispose();
    _amount.dispose();
    _merchant.dispose();
    _note.dispose();
    super.dispose();
  }

  /// The accounts or cards offered for [_method], with the edited expense's
  /// removed one added, so it still shows.
  List<LedgerAccount> _choices(List<LedgerAccount> live) {
    final removed = _removedAccount;
    if (removed == null || removed.kind != _method.fundingKind || live.any((a) => a.id == removed.id)) return live;
    return [...live, removed];
  }

  /// The chosen account or card: the one picked, else the default, else the
  /// only one there is.
  String? _chosen(List<LedgerAccount> choices) {
    if (_method == PaymentMethod.cash) return SystemAccounts.cash;
    if (_accountId != null && choices.any((a) => a.id == _accountId)) return _accountId;
    final defaults = choices.where((a) => a.isDefault);
    if (defaults.isNotEmpty) return defaults.first.id;
    return choices.length == 1 ? choices.single.id : null;
  }

  /// Adds a category from the form and chooses it.
  Future<void> _newCategory() async {
    // Close the number pad and wait until it is down, so the name field
    // opens the letter keyboard afresh; switching in one go leaves some
    // keyboards (Gboard on the owner's phone) on numbers.
    _restingFocus.requestFocus();
    final view = View.of(context);
    for (var i = 0; i < 20 && view.viewInsets.bottom > 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    if (!mounted) return;
    final id = await showNewCategorySheet(context);
    if (id == null || !mounted) return;
    setState(() {
      _categoryId = id;
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

  Future<void> _save({required int amountPaise, required String fundingId, required String categoryName}) async {
    final ledger = ref.read(ledgerEngineProvider);
    final original = _original;
    // An SMS-only method, such as debit card, shows as UPI. It is kept as
    // stored unless the method was changed here.
    final keep = original != null && original.method.shownAs == _method;
    final method = keep ? original.method : _method;
    final channel = keep ? original.channel : null;
    String? text(TextEditingController field) => field.text.trim().isEmpty ? null : field.text.trim();
    setState(() => _saving = true);
    try {
      final ExpenseDone done;
      if (original == null) {
        final id = await ledger.recordExpense(
          amountPaise: amountPaise,
          method: method,
          fundingAccountId: fundingId,
          categoryId: _categoryId!,
          occurredAt: _when,
          merchant: text(_merchant),
          note: text(_note),
          channel: channel,
        );
        done = ExpenseDone(
          id: id,
          revision: 1,
          message: 'Saved ${formatRupees(amountPaise)} · $categoryName',
          undoneMessage: 'Removed ${formatRupees(amountPaise)}',
        );
      } else {
        await ledger.editExpense(
          original.id,
          amountPaise: amountPaise,
          method: method,
          fundingAccountId: fundingId,
          categoryId: _categoryId!,
          occurredAt: _when,
          merchant: text(_merchant),
          note: text(_note),
          channel: channel,
        );
        done = ExpenseDone(
          id: original.id,
          revision: original.revision + 1,
          message: 'Saved changes',
          undoneMessage: 'Change undone',
        );
      }
      if (mounted) Navigator.of(context).pop(done);
    } on LedgerException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _failureText(error.failure);
      });
    }
  }

  Future<void> _delete() async {
    final original = _original!;
    setState(() => _saving = true);
    try {
      await ref.read(ledgerEngineProvider).delete(original.id);
      if (!mounted) return;
      final amount = formatRupees(original.amountPaise);
      Navigator.of(context).pop(
        ExpenseDone(
          id: original.id,
          revision: original.revision + 1,
          message: 'Deleted $amount',
          undoneMessage: 'Brought back $amount',
        ),
      );
    } on LedgerException catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _failureText(error.failure);
      });
    }
  }

  static String _failureText(LedgerFailure failure) => switch (failure) {
    LedgerFailure.accountRemoved => 'That account was removed. Pick another one.',
    LedgerFailure.hasLiveRefunds => 'This expense has refunds. Delete them first.',
    LedgerFailure.refundExceedsOriginal => 'Its refunds already add up to more than that amount.',
    LedgerFailure.notFound => 'This expense no longer exists.',
    _ => 'Could not save. Check the amount, the account and the category.',
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final banksAsync = ref.watch(accountsOfKindProvider(AccountKind.bank));
    final cardsAsync = ref.watch(accountsOfKindProvider(AccountKind.creditCard));
    final cashAsync = ref.watch(cashInHandProvider);
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final all = [banksAsync, cardsAsync, cashAsync, categoriesAsync];
    final failed = all.any((a) => a.hasError);
    final ready = all.every((a) => a.hasValue) && !_loading && (!_editing || _original != null);

    final accent = switch (_method) {
      PaymentMethod.creditCard => c.creditCard,
      PaymentMethod.cash => c.cash,
      _ => c.money,
    };
    final amountPaise = parseRupees(_amount.text);
    final validAmount = amountPaise != null && amountPaise > 0;
    final future = _when.isAfter(widget.clock());

    Widget body;
    String? fundingId;
    var categoryName = '';
    if (failed) {
      body = const Align(
        alignment: Alignment.topCenter,
        child: LoopdErrorNote('The form could not be loaded. Close this and open it again.'),
      );
    } else if (!ready) {
      body = _error == null
          ? const SizedBox.expand()
          : Align(alignment: Alignment.topCenter, child: LoopdErrorNote(_error!));
    } else {
      final list = _method == PaymentMethod.creditCard ? cardsAsync.requireValue : banksAsync.requireValue;
      final choices = _choices(list);
      fundingId = _chosen(choices);
      final categories = categoriesAsync.requireValue;
      categoryName = categories.where((k) => k.id == _categoryId).firstOrNull?.name ?? '';
      final cash = cashAsync.requireValue.balance.paise;
      // When editing a cash expense, its own amount is already out of the
      // balance; put it back to say what is left.
      final cashBefore = cash + (_original?.method == PaymentMethod.cash ? _original!.amountPaise : 0);
      final message = future ? 'That time is still to come. Pick a time that has passed.' : _error;
      body = ListView(
        key: ExpenseSheet.formKey,
        padding: const EdgeInsets.only(bottom: LoopdSpace.lg),
        children: [
          _AmountField(controller: _amount, accent: accent, autofocus: !_editing),
          const SizedBox(height: 22),
          _Details(
            merchant: _merchant,
            note: _note,
            whenLabel: whenText(_when, now: widget.clock()),
            onWhen: _pickWhen,
          ),
          const SizedBox(height: 22),
          _SectionTitle('Paid with'),
          const SizedBox(height: 10),
          LoopdSegmented<PaymentMethod>(
            segments: [
              LoopdSegment(value: PaymentMethod.upi, label: 'UPI', color: c.money),
              LoopdSegment(value: PaymentMethod.creditCard, label: 'Credit Card', color: c.creditCard),
              LoopdSegment(value: PaymentMethod.cash, label: 'Cash', color: c.cash),
            ],
            selected: _method,
            onChanged: (method) => setState(() {
              if (method == _method) return;
              _method = method;
              _accountId = null;
              _error = null;
            }),
          ),
          const SizedBox(height: 10),
          if (_method == PaymentMethod.cash)
            _CashChoice(beforePaise: cashBefore, spendPaise: validAmount ? amountPaise : 0)
          else
            _AccountList(
              accounts: choices,
              chosenId: fundingId,
              removedId: _removedAccount?.id,
              isCard: _method == PaymentMethod.creditCard,
              accent: accent,
              onPick: (id) => setState(() {
                _accountId = id;
                _error = null;
              }),
              onAdd: widget.onAddAccount == null ? null : () => widget.onAddAccount!(context, _method.fundingKind),
            ),
          const SizedBox(height: 22),
          _SectionTitle('Category'),
          const SizedBox(height: 10),
          _CategoryGrid(
            categories: categories,
            chosenId: _categoryId,
            onPick: (id) => setState(() {
              _categoryId = id;
              _error = null;
            }),
            onNew: categories.length >= LedgerEngine.categoryMax
                ? () => showLoopdToast(context, CategorySheet.fullMessage)
                : _newCategory,
          ),
          if (message != null) ...[const SizedBox(height: LoopdSpace.lg), LoopdErrorNote(message)],
        ],
      );
    }

    final canSave = ready && validAmount && fundingId != null && _categoryId != null && !future && !_saving;
    final title = _editing ? 'Edit expense' : 'Add expense';
    return Focus(
      focusNode: _restingFocus,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: LoopdType.title.copyWith(color: c.textPrimary)),
                ),
              ),
              if (_editing && _original != null) ...[
                LoopdRoundButton(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete expense',
                  size: 40,
                  background: c.dangerTint,
                  foreground: c.danger,
                  onTap: _saving ? null : _delete,
                ),
                const SizedBox(width: LoopdSpace.sm),
              ],
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
          const SizedBox(height: LoopdSpace.md),
          Expanded(
            child: AnimatedSwitcher(duration: LoopdMotion.of(context).quick, child: body),
          ),
          Divider(height: 1, thickness: 1, color: c.line),
          const SizedBox(height: 14),
          LoopdButton(
            label: validAmount ? 'Save ${formatRupees(amountPaise)}' : 'Save',
            onTap: canSave
                ? () => _save(amountPaise: amountPaise, fundingId: fundingId!, categoryName: categoryName)
                : null,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(text, style: LoopdType.small.copyWith(color: context.colors.textMuted)),
  );
}

/// The big centred amount, with the ₹ in the method's colour.
class _AmountField extends StatelessWidget {
  const _AmountField({required this.controller, required this.accent, required this.autofocus});

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
                  key: ExpenseSheet.amountFieldKey,
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
      ],
    );
  }
}

/// Paid to, Date and time, and Note, in one outlined card.
class _Details extends StatelessWidget {
  const _Details({required this.merchant, required this.note, required this.whenLabel, required this.onWhen});

  final TextEditingController merchant;
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
          Padding(
            padding: const EdgeInsets.fromLTRB(LoopdSpace.lg, 14, LoopdSpace.lg, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paid to', style: LoopdType.caption.copyWith(color: c.textMuted)),
                const SizedBox(height: LoopdSpace.xs),
                TextField(
                  key: ExpenseSheet.merchantFieldKey,
                  controller: merchant,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  style: LoopdType.heading.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
                  decoration: InputDecoration.collapsed(
                    hintText: 'Optional, e.g. Swiggy',
                    hintStyle: LoopdType.heading.copyWith(color: c.textMuted, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          divider,
          LoopdPressable(
            key: ExpenseSheet.whenKey,
            onTap: onWhen,
            label: 'Date and time, $whenLabel',
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 54),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg),
                child: Row(
                  children: [
                    Expanded(child: Text('Date and time', style: rowLabel)),
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
                      key: ExpenseSheet.noteFieldKey,
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

/// The bank accounts (UPI) or cards to pay from, one chosen.
class _AccountList extends StatelessWidget {
  const _AccountList({
    required this.accounts,
    required this.chosenId,
    required this.removedId,
    required this.isCard,
    required this.accent,
    required this.onPick,
    required this.onAdd,
  });

  final List<LedgerAccount> accounts;
  final String? chosenId;
  final String? removedId;
  final bool isCard;
  final Color accent;
  final ValueChanged<String> onPick;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (accounts.isEmpty) {
      final what = isCard ? 'credit card' : 'bank account';
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isCard ? 'No credit cards yet.' : 'No bank accounts yet. UPI is paid from one.',
            style: LoopdType.small.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
          ),
          if (onAdd != null) ...[
            const SizedBox(height: 10),
            LoopdDashedButton(label: 'Add $what', color: accent, onTap: onAdd),
          ],
        ],
      );
    }
    final tint = isCard ? c.creditCardTint : c.moneyTint;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(LoopdRadius.cardLarge),
        border: Border.all(color: c.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (final (index, account) in accounts.indexed) ...[
            if (index > 0) Divider(height: 1, thickness: 1, color: c.line),
            _AccountRow(
              account: account,
              chosen: account.id == chosenId,
              removed: account.id == removedId,
              accent: accent,
              tint: tint,
              onTap: () => onPick(account.id),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.chosen,
    required this.removed,
    required this.accent,
    required this.tint,
    required this.onTap,
  });

  final LedgerAccount account;
  final bool chosen;

  /// An account removed since the expense was saved.
  final bool removed;
  final Color accent;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = LoopdMotion.of(context);
    // Default or Removed, next to the nickname. On the chosen row, whose
    // background is already the tint, the pill sits on the plain surface so
    // it still shows.
    AccountTag? tag;
    if (removed) {
      tag = AccountTag(label: 'Removed', color: c.textSecondary, tint: chosen ? c.surface : c.surfaceRaised);
    } else if (account.isDefault) {
      final look = AccountTag.defaultFor(account.kind, c);
      tag = chosen ? AccountTag(label: look.label, color: look.color, tint: c.surface) : look;
    }
    return LoopdPressable(
      onTap: onTap,
      selected: chosen,
      label: [account.nickname, ?tag?.label, account.bankAndDigits].join(', '),
      pressedScale: 1,
      child: AnimatedContainer(
        duration: motion.quick,
        color: chosen ? tint : const Color(0x00000000),
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: 10),
        child: Row(
          children: [
            LoopdMiniCard(color: bankColour(account.bankName, c)),
            const SizedBox(width: LoopdSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LoopdType.bodyStrong.copyWith(color: c.textPrimary),
                        ),
                      ),
                      if (tag != null) ...[const SizedBox(width: LoopdSpace.sm), tag],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(account.bankAndDigits, style: LoopdType.caption.copyWith(color: c.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: LoopdSpace.md),
            AnimatedContainer(
              duration: motion.quick,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: chosen ? accent : c.line, width: chosen ? 7 : 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cash in hand as the source, with what is left after this expense.
class _CashChoice extends StatelessWidget {
  const _CashChoice({required this.beforePaise, required this.spendPaise});

  final int beforePaise;
  final int spendPaise;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final left = beforePaise - spendPaise;
    final after = left >= 0 ? '${formatRupees(left)} after this' : 'more than you have · update your cash';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: 10),
          decoration: BoxDecoration(
            color: c.cashTint,
            borderRadius: BorderRadius.circular(LoopdRadius.cardLarge),
            border: Border.all(color: c.cash, width: 1.5),
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 46,
                  height: 30,
                  decoration: BoxDecoration(color: c.cash, borderRadius: BorderRadius.circular(6)),
                  child: Icon(Icons.payments_outlined, size: 20, color: c.onAccent),
                ),
              ),
              const SizedBox(width: LoopdSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cash in hand', style: LoopdType.bodyStrong.copyWith(color: c.textPrimary)),
                    const SizedBox(height: 2),
                    Text(
                      '${formatRupees(beforePaise)} now · $after',
                      style: LoopdType.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Cash comes in from ATM withdrawals you confirm in the Review Inbox, '
          'or when you update your cash in Accounts and cards.',
          style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500, height: 1.5),
        ),
      ],
    );
  }
}

/// The categories as a three-column grid of chips, one chosen, and a dashed
/// New category chip at the end.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.categories, required this.chosenId, required this.onPick, required this.onNew});

  final List<LedgerCategory> categories;
  final String? chosenId;
  final ValueChanged<String> onPick;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    const gap = LoopdSpace.sm;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 2 * gap) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final category in categories)
              SizedBox(
                width: width,
                child: _CategoryChip(
                  category: category,
                  chosen: category.id == chosenId,
                  onTap: () => onPick(category.id),
                  colors: c,
                ),
              ),
            SizedBox(
              width: width,
              child: LoopdDashedButton(
                label: 'New',
                color: c.textSecondary,
                height: 46,
                radius: LoopdRadius.inner,
                onTap: onNew,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category, required this.chosen, required this.onTap, required this.colors});

  final LedgerCategory category;
  final bool chosen;
  final VoidCallback onTap;
  final LoopdColors colors;

  @override
  Widget build(BuildContext context) {
    final c = colors;
    final dot = LoopdCategoryColours.expenseAt(category.colour);
    return LoopdPressable(
      onTap: onTap,
      selected: chosen,
      label: category.name,
      child: AnimatedContainer(
        duration: LoopdMotion.of(context).quick,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.sm),
        decoration: BoxDecoration(
          color: chosen ? c.surfaceRaised : c.surface,
          borderRadius: BorderRadius.circular(LoopdRadius.inner),
          border: Border.all(color: chosen ? dot : c.line, width: chosen ? 1.5 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: LoopdSpace.sm),
            // A long name, such as Subscriptions, shrinks a little to fit.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(category.name, maxLines: 1, style: LoopdType.small.copyWith(color: c.textPrimary)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
