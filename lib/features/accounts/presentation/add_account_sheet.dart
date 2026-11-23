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
import '../../../design_system/components/loopd_round_button.dart';
import '../../../design_system/components/loopd_segmented.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/components/loopd_switch.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_motion.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'account_look.dart';
import 'bill_due_sheet.dart';
import 'providers/accounts_providers.dart';

/// Opens the Add bank account or Add credit card sheet (mockup
/// `AddAccount.dc.html`, screens 4b and 4c). Returns the saved nickname, or
/// null when closed without saving.
Future<String?> showAddAccountSheet(BuildContext context, {required AccountKind kind}) => showLoopdSheet<String>(
  context: context,
  builder: (_) => AddAccountSheet(initialKind: kind),
);

/// One sheet for both kinds, with a type switch at the top: a live card
/// preview, a searchable bank list, nickname, last four digits and a default
/// switch. Nothing becomes the default unless you turn the switch on.
class AddAccountSheet extends ConsumerStatefulWidget {
  const AddAccountSheet({required this.initialKind, super.key});

  final AccountKind initialKind;

  static const bankFieldKey = ValueKey('add-account-bank');
  static const nicknameFieldKey = ValueKey('add-account-nickname');
  static const last4FieldKey = ValueKey('add-account-last4');

  @override
  ConsumerState<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends ConsumerState<AddAccountSheet> {
  late AccountKind _kind = widget.initialKind;
  final _query = TextEditingController();
  final _nickname = TextEditingController();
  final _last4 = TextEditingController();
  final _bankFocus = FocusNode();

  /// A bank picked from the list.
  Bank? _chosen;

  /// A bank typed by hand ("Use … as a new bank").
  String? _typedBank;
  bool _open = false;
  bool _makeDefault = false;
  int? _dueDay;
  bool _saving = false;
  String? _error;

  bool get _isCard => _kind == AccountKind.creditCard;
  String? get _bankName => _chosen?.name ?? _typedBank;

  @override
  void initState() {
    super.initState();
    _bankFocus.addListener(() {
      if (_bankFocus.hasFocus && !_open) setState(() => _open = true);
    });
    for (final field in [_nickname, _last4]) {
      field.addListener(() => setState(() => _error = null));
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _nickname.dispose();
    _last4.dispose();
    _bankFocus.dispose();
    super.dispose();
  }

  void _setKind(AccountKind kind) => setState(() {
    _kind = kind;
    _makeDefault = false;
    _error = null;
    // A card-only entry, such as a bank's card division, is not a bank account.
    if (kind == AccountKind.bank && (_chosen?.cardsOnly ?? false)) {
      _chosen = null;
      _query.clear();
    }
  });

  void _pick(Bank bank) {
    _bankFocus.unfocus();
    setState(() {
      _chosen = bank;
      _typedBank = null;
      _query.text = bank.name;
      _open = false;
      _error = null;
    });
  }

  void _pickTyped() {
    _bankFocus.unfocus();
    setState(() {
      _chosen = null;
      _typedBank = _query.text.trim();
      _open = false;
      _error = null;
    });
  }

  Future<void> _pickDueDay() async {
    FocusScope.of(context).unfocus();
    final picked = await showBillDueSheet(context, card: null, day: _dueDay);
    if (picked != null && mounted) setState(() => _dueDay = picked.day);
  }

  /// The arrow opens or closes the list, and always puts the keyboard away.
  void _toggleList() {
    _bankFocus.unfocus();
    setState(() => _open = !_open);
  }

  Future<void> _save() async {
    final bankName = _bankName!;
    final last4 = _last4.text;
    final nickname = _nickname.text.trim().isEmpty ? bankName : _nickname.text.trim();
    setState(() => _saving = true);
    try {
      await ref
          .read(ledgerEngineProvider)
          .addAccount(
            kind: _kind,
            name: nickname,
            bankName: bankName,
            bankCode: _chosen?.code,
            last4: last4,
            billDueDay: _isCard ? _dueDay : null,
            makeDefault: _makeDefault,
          );
      if (mounted) Navigator.of(context).pop(nickname);
    } on LedgerException catch (error) {
      // The sheet already checks the digits as you type; this is the ledger's
      // own check, for an account added somewhere else at the same moment.
      setState(() {
        _saving = false;
        _error = error.failure == LedgerFailure.duplicateAccount
            ? _takenMessage(last4, null)
            : 'Check the bank and the last four digits.';
      });
    }
  }

  /// The bank account or card of this kind that already has [last4], if any.
  LedgerAccount? _takenBy(String last4) {
    if (last4.length != 4) return null;
    final saved = ref.watch(accountsOfKindProvider(_kind)).value ?? const <LedgerAccount>[];
    for (final account in saved) {
      if (account.last4 == last4) return account;
    }
    return null;
  }

  String _takenMessage(String last4, LedgerAccount? owner) {
    final kind = _isCard ? 'card' : 'bank account';
    return owner == null
        ? 'A $kind ending ••$last4 is already saved.'
        : '${owner.nickname} already ends ••$last4. Each $kind needs its own last four digits.';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final accent = _isCard ? c.creditCard : c.money;
    final taken = _takenBy(_last4.text);
    final error = taken != null ? _takenMessage(_last4.text, taken) : _error;
    final ready = _bankName != null && _last4.text.length == 4 && taken == null && !_saving;
    final title = _isCard ? 'Add credit card' : 'Add bank account';
    return SingleChildScrollView(
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
          const SizedBox(height: LoopdSpace.lg),
          LoopdSegmented<AccountKind>(
            segments: [
              LoopdSegment(value: AccountKind.bank, label: 'Bank account', color: c.money),
              LoopdSegment(value: AccountKind.creditCard, label: 'Credit card', color: c.creditCard),
            ],
            selected: _kind,
            onChanged: _setKind,
          ),
          const SizedBox(height: LoopdSpace.lg),
          _CardPreview(
            colour: bankColour(_bankName, c),
            bank: _bankName ?? 'Choose a bank',
            kindLabel: _isCard ? 'Credit card' : 'Used for UPI',
            nickname: _nickname.text.trim().isEmpty ? (_bankName ?? 'Nickname') : _nickname.text.trim(),
            last4: _last4.text.padRight(4, '0'),
          ),
          const SizedBox(height: LoopdSpace.lg),
          Text('Bank', style: LoopdType.caption.copyWith(color: c.textMuted)),
          const SizedBox(height: 6),
          _BankField(
            controller: _query,
            focusNode: _bankFocus,
            open: _open,
            accent: accent,
            chosen: _chosen,
            isCard: _isCard,
            onChanged: () => setState(() {
              _chosen = null;
              _typedBank = null;
              _open = true;
              _error = null;
            }),
            onToggle: _toggleList,
            onPick: _pick,
            onPickTyped: _pickTyped,
          ),
          if (!_open && _bankName != null) ...[
            const SizedBox(height: LoopdSpace.sm),
            _SenderNote(code: _chosen?.code, accent: accent),
          ],
          const SizedBox(height: LoopdSpace.lg),
          _Fields(
            nickname: _nickname,
            last4: _last4,
            nicknameHint: _isCard ? 'e.g. Kiwi' : 'e.g. Primary',
            defaultLabel: _isCard ? 'Default credit card' : 'Default for UPI',
            isDefault: _makeDefault,
            accent: accent,
            onDefault: (value) => setState(() => _makeDefault = value),
            dueRow: _isCard ? BillDueRow(day: _dueDay, onTap: _pickDueDay, bordered: false) : null,
          ),
          if (error != null) ...[const SizedBox(height: LoopdSpace.sm), LoopdErrorNote(error)],
          const SizedBox(height: LoopdSpace.xl),
          LoopdButton(label: _isCard ? 'Add card' : 'Add account', onTap: ready ? _save : null),
        ],
      ),
    );
  }
}

/// The live preview: the card as it will look, in the bank's colour.
class _CardPreview extends StatelessWidget {
  const _CardPreview({
    required this.colour,
    required this.bank,
    required this.kindLabel,
    required this.nickname,
    required this.last4,
  });

  final Color colour;
  final String bank;
  final String kindLabel;
  final String nickname;
  final String last4;

  static const _white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AnimatedContainer(
      duration: LoopdMotion.of(context).emphasis,
      height: 132,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: LoopdSpace.lg),
      decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(LoopdRadius.card)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  bank,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LoopdType.small.copyWith(color: _white),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: _white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(LoopdRadius.pill),
                ),
                child: Text(
                  kindLabel,
                  style: LoopdType.micro.copyWith(color: _white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 30,
                height: 22,
                decoration: BoxDecoration(color: const Color(0xFFFCD34D), borderRadius: BorderRadius.circular(5)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nickname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LoopdType.title.copyWith(color: _white, fontSize: 20),
                ),
              ),
              Text(
                '•••• $last4',
                style: LoopdType.code.copyWith(
                  color: _white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// The search field with its dropdown: typing filters the list and
/// highlights the match; a missing bank can be added by name.
class _BankField extends StatelessWidget {
  const _BankField({
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
  });

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
                    key: AddAccountSheet.bankFieldKey,
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

/// Under the chosen bank: which SMS sender is linked, or, for a bank typed
/// by hand, that its SMS are not linked yet. One soft strip either way.
class _SenderNote extends StatelessWidget {
  const _SenderNote({required this.code, required this.accent});

  /// Null for a bank typed by hand.
  final String? code;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final style = LoopdType.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500);
    final linked = code != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.md, vertical: 10),
      decoration: BoxDecoration(
        color: linked ? accent.withValues(alpha: 0.1) : c.surfaceRaised,
        borderRadius: BorderRadius.circular(LoopdRadius.tile),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            linked ? Icons.sms_outlined : Icons.info_outline_rounded,
            size: 16,
            color: linked ? accent : c.textMuted,
          ),
          const SizedBox(width: LoopdSpace.sm),
          Expanded(
            child: linked
                ? Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'SMS from '),
                        TextSpan(
                          text: code,
                          style: LoopdType.code.copyWith(color: c.textPrimary, fontSize: 12),
                        ),
                        const TextSpan(text: ' will be linked here, whatever the prefix.'),
                      ],
                    ),
                    style: style,
                  )
                : Text(
                    'This bank is not in the list yet, so its SMS are not linked. '
                    'You can still add its expenses by hand.',
                    style: style,
                  ),
          ),
        ],
      ),
    );
  }
}

/// Nickname, last four digits and the default switch, on one outlined card.
class _Fields extends StatelessWidget {
  const _Fields({
    required this.nickname,
    required this.last4,
    required this.nicknameHint,
    required this.defaultLabel,
    required this.isDefault,
    required this.accent,
    required this.onDefault,
    this.dueRow,
  });

  /// Bill due date, on a credit card only.
  final Widget? dueRow;

  final TextEditingController nickname;
  final TextEditingController last4;
  final String nicknameHint;
  final String defaultLabel;
  final bool isDefault;
  final Color accent;
  final ValueChanged<bool> onDefault;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final label = LoopdType.label.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500);
    Widget row(Widget child) => ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 54),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14), child: child),
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          row(
            Row(
              children: [
                Text('Nickname', style: label),
                const SizedBox(width: LoopdSpace.md),
                Expanded(
                  child: TextField(
                    key: AddAccountSheet.nicknameFieldKey,
                    controller: nickname,
                    textAlign: TextAlign.end,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [LengthLimitingTextInputFormatter(24)],
                    style: LoopdType.bodyStrong.copyWith(color: c.textPrimary, fontSize: 16),
                    cursorColor: accent,
                    decoration: InputDecoration.collapsed(
                      hintText: nicknameHint,
                      hintStyle: LoopdType.bodyStrong.copyWith(color: c.textMuted, fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: c.line),
          row(
            Row(
              children: [
                Expanded(child: Text('Last four digits', style: label)),
                SizedBox(
                  width: 96,
                  child: TextField(
                    key: AddAccountSheet.last4FieldKey,
                    controller: last4,
                    textAlign: TextAlign.end,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                    style: LoopdType.code.copyWith(
                      color: c.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                    cursorColor: accent,
                    decoration: InputDecoration.collapsed(
                      hintText: '0000',
                      hintStyle: LoopdType.code.copyWith(
                        color: c.textMuted,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: c.line),
          if (dueRow != null) ...[dueRow!, Divider(height: 1, thickness: 1, color: c.line)],
          row(
            Row(
              children: [
                Expanded(child: Text(defaultLabel, style: label)),
                LoopdSwitch(label: defaultLabel, value: isDefault, activeColor: accent, onChanged: onDefault),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
