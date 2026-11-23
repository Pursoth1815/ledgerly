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
import 'delete_refunded_sheet.dart';
import 'form_parts.dart';
import 'providers/expense_providers.dart';
import 'refund_sheet.dart' show showRefundSheet;
import 'spending_parts.dart' show categoryLook;
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
  showDoneToast(context, ledger, done);
}

/// Says what a money form did, with Undo.
void showDoneToast(BuildContext context, LedgerEngine ledger, ExpenseDone done) => showLoopdToast(
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
    final ledger = ref.read(ledgerEngineProvider);
    FocusScope.of(context).unfocus();
    // A purchase with refunds goes only together with them, once you have
    // seen them and said so (proposal section 13).
    final refunds = await ledger.refundsOf(original.id);
    if (refunds.isNotEmpty) {
      final lines = <RefundLine>[
        for (final refund in refunds)
          (
            refund: refund,
            accountName: refund.destinationAccountId == SystemAccounts.cash
                ? 'Cash'
                : (await ledger.getAccount(refund.destinationAccountId))?.nickname ?? 'Removed account',
          ),
      ];
      if (!mounted) return;
      final categories = ref.read(expenseCategoriesProvider).value ?? const <LedgerCategory>[];
      final sure = await showDeleteRefundedSheet(
        context,
        name: original.merchant ?? categoryLook(original.categoryId, categories).name,
        amountPaise: original.amountPaise,
        refunds: lines,
        now: widget.clock(),
      );
      if (!sure) return;
    }
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      await ledger.delete(original.id, withRefunds: refunds.isNotEmpty);
      if (!mounted) return;
      final amount = formatRupees(original.amountPaise);
      final extra = switch (refunds.length) {
        0 => '',
        1 => ' and its refund',
        _ => ' and its ${refunds.length} refunds',
      };
      Navigator.of(context).pop(
        ExpenseDone(
          id: original.id,
          revision: original.revision + 1,
          message: 'Deleted $amount$extra',
          undoneMessage: 'Brought back $amount$extra',
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
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final all = [banksAsync, cardsAsync, categoriesAsync];
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
    final message = future ? 'That time is still to come. Pick a time that has passed.' : _error;

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
      body = ListView(
        key: ExpenseSheet.formKey,
        padding: const EdgeInsets.only(bottom: LoopdSpace.lg),
        children: [
          AmountField(fieldKey: ExpenseSheet.amountFieldKey, controller: _amount, accent: accent, autofocus: !_editing),
          const SizedBox(height: 22),
          DetailsCard(
            name: _merchant,
            nameLabel: 'Paid to',
            nameHint: 'Optional, e.g. Swiggy',
            nameKey: ExpenseSheet.merchantFieldKey,
            note: _note,
            noteKey: ExpenseSheet.noteFieldKey,
            whenKey: ExpenseSheet.whenKey,
            whenLabel: whenText(_when, now: widget.clock()),
            onWhen: _pickWhen,
          ),
          const SizedBox(height: 22),
          FormSectionTitle('Paid with'),
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
            const _CashChoice()
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
          FormSectionTitle('Category'),
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
          if (_original != null) ...[
            const SizedBox(height: 22),
            const FormSectionTitle('Refunds'),
            const SizedBox(height: 10),
            _Refunds(
              expense: _original!,
              enabled: !_saving,
              onAdd: () => showRefundSheet(context, expenseId: _original!.id, clock: widget.clock),
            ),
            const SizedBox(height: LoopdSpace.lg),
            Semantics(
              container: true,
              child: LoopdButton(
                label: 'Delete expense',
                style: LoopdButtonStyle.danger,
                onTap: _saving ? null : _delete,
              ),
            ),
          ],
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
          // Kept above the button, so a problem is never off screen.
          if (ready && message != null) ...[
            const SizedBox(height: LoopdSpace.sm),
            LoopdErrorNote(message),
            const SizedBox(height: LoopdSpace.sm),
          ],
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

/// Add refund and what has come back so far, kept live while refunds are
/// added over this sheet. Faded once the whole amount has come back.
class _Refunds extends ConsumerWidget {
  const _Refunds({required this.expense, required this.enabled, required this.onAdd});

  final ExpenseRecord expense;
  final bool enabled;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final refunded = ref.watch(expenseRefundedProvider(expense.id)).value ?? 0;
    final full = refunded >= expense.amountPaise;
    final status = refunded == 0
        ? 'Nothing refunded yet. A refund comes off this purchase’s month.'
        : full
        ? 'Fully refunded.'
        : '${formatRupees(refunded)} refunded. A refund comes off this purchase’s month.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          child: LoopdButton(
            label: 'Add refund',
            icon: Icons.undo_rounded,
            style: LoopdButtonStyle.outlined,
            onTap: enabled && !full ? onAdd : null,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          status,
          style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500, height: 1.5),
        ),
      ],
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

/// Cash as the source. Loopd records the spend and keeps no cash balance.
class _CashChoice extends StatelessWidget {
  const _CashChoice();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
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
          Text('Paid in cash', style: LoopdType.bodyStrong.copyWith(color: c.textPrimary)),
        ],
      ),
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
