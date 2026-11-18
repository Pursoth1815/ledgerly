import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ledger/ledger_engine.dart';
import '../../../core/ledger/ledger_types.dart';
import '../../../core/ledger/rupees.dart';
import '../../../design_system/components/loopd_dashed_button.dart';
import '../../../design_system/components/loopd_error_note.dart';
import '../../../design_system/components/loopd_pressable.dart';
import '../../../design_system/components/loopd_round_button.dart';
import '../../../design_system/components/loopd_sheet.dart';
import '../../../design_system/components/loopd_source_strip.dart';
import '../../../design_system/components/loopd_toast.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_motion.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';
import 'account_look.dart';
import 'account_options_sheet.dart';
import 'add_account_sheet.dart';
import 'providers/accounts_providers.dart';
import 'short_dates.dart';
import 'update_count_sheet.dart';

/// Opens Accounts and cards as a tall sheet over the whole app, tab bar
/// included (owner, 18 Nov 2026: a sheet, not a page, so it can open from
/// any screen and never stays behind on a tab). Close it to switch tabs.
Future<void> showAccountsSheet(BuildContext context, {DateTime Function() clock = DateTime.now}) =>
    showLoopdSheet<void>(
      context: context,
      tall: true,
      builder: (_) => AccountsSheet(clock: clock),
    );

/// Accounts and cards (mockup `Accounts.dc.html`, proposal section 4): Cash
/// in hand with Update cash, the bank accounts used for UPI, and the credit
/// cards, each with what it spent this month. Tapping one offers Make default
/// and Remove.
///
/// The sheet keeps one height from the start, and its list appears only once
/// everything has loaded, so nothing shows half-built or jumps into place.
class AccountsSheet extends ConsumerWidget {
  const AccountsSheet({this.clock = DateTime.now, super.key});

  /// The current time; replaced in tests.
  final DateTime Function() clock;

  /// Finds the loaded list in tests.
  static const listKey = ValueKey('accounts-list');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final now = clock();
    final month = DateTime(now.year, now.month);
    final spendingAsync = ref.watch(monthSpendingProvider(month));
    final banksAsync = ref.watch(accountsOfKindProvider(AccountKind.bank));
    final cardsAsync = ref.watch(accountsOfKindProvider(AccountKind.creditCard));
    final cashAsync = ref.watch(cashInHandProvider);
    final all = [spendingAsync, banksAsync, cardsAsync, cashAsync];
    final failed = all.any((a) => a.hasError);
    final ready = all.every((a) => a.hasValue);

    final Widget body;
    if (failed) {
      body = const Align(
        alignment: Alignment.topCenter,
        child: LoopdErrorNote('Accounts could not be loaded. Close this and open it again.'),
      );
    } else if (!ready) {
      body = const SizedBox.expand();
    } else {
      body = _AccountsList(
        key: listKey,
        month: month,
        spending: spendingAsync.requireValue,
        banks: banksAsync.requireValue,
        cards: cardsAsync.requireValue,
        cash: cashAsync.requireValue,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text('Accounts and cards', style: LoopdType.title.copyWith(color: c.textPrimary)),
                  ),
                  const SizedBox(height: LoopdSpace.xs),
                  Text(
                    'The last four digits link each SMS to the right one.',
                    style: LoopdType.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: LoopdSpace.md),
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
        Expanded(
          child: AnimatedSwitcher(duration: LoopdMotion.of(context).quick, child: body),
        ),
      ],
    );
  }
}

/// The three sections, drawn only once all of them have loaded.
class _AccountsList extends StatelessWidget {
  const _AccountsList({
    required this.month,
    required this.spending,
    required this.banks,
    required this.cards,
    required this.cash,
    super.key,
  });

  final DateTime month;
  final Map<String, int> spending;
  final List<LedgerAccount> banks;
  final List<LedgerAccount> cards;
  final CashInHand cash;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final monthName = shortMonth(month);
    int total(List<LedgerAccount> list) => list.fold(0, (sum, a) => sum + (spending[a.id] ?? 0));

    Future<void> add(AccountKind kind) async {
      final added = await showAddAccountSheet(context, kind: kind);
      if (added != null && context.mounted) showLoopdToast(context, 'Added $added');
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: LoopdSpace.sm),
      children: [
        _SectionHeader(
          // "Cash", not "Cash in hand": the amount on the right is cash
          // spending, not the balance (owner, 18 Nov 2026).
          title: 'Cash',
          total: '${formatRupees(spending[SystemAccounts.cash] ?? 0)} in $monthName',
          color: c.cash,
        ),
        const SizedBox(height: 10),
        _CashCard(
          cash: cash,
          onUpdate: () async {
            final message = await showUpdateCountSheet(context);
            if (message != null && context.mounted) showLoopdToast(context, message);
          },
        ),
        const SizedBox(height: 22),
        _SectionHeader(
          title: 'Bank accounts · used for UPI',
          total: banks.isEmpty ? null : '${formatRupees(total(banks))} in $monthName',
          color: c.money,
        ),
        const SizedBox(height: 10),
        if (banks.isNotEmpty) ...[_BankList(banks: banks, spending: spending), const SizedBox(height: 10)],
        LoopdDashedButton(label: 'Add bank account', color: c.money, onTap: () => add(AccountKind.bank)),
        const SizedBox(height: 22),
        _SectionHeader(
          title: 'Credit cards',
          total: cards.isEmpty ? null : '${formatRupees(total(cards))} in $monthName',
          color: c.creditCard,
        ),
        const SizedBox(height: 10),
        for (final card in cards) ...[
          _CreditCard(card: card, spent: spending[card.id] ?? 0),
          const SizedBox(height: 10),
        ],
        LoopdDashedButton(label: 'Add credit card', color: c.creditCard, onTap: () => add(AccountKind.creditCard)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color, this.total});

  final String title;

  /// This month's spending, such as "₹4,180 in Nov"; hidden when empty.
  final String? total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: LoopdType.small.copyWith(color: c.textMuted)),
          ),
        ),
        if (total != null)
          Text(
            total!,
            style: LoopdType.small.copyWith(color: color, fontFeatures: const [FontFeature.tabularFigures()]),
          ),
      ],
    );
  }
}

/// The sky-blue Cash in hand card. It starts at ₹0; each count sets it. The
/// line under the amount names the newest of the last count and the last
/// money in from a bank (an ATM withdrawal).
class _CashCard extends StatelessWidget {
  const _CashCard({required this.cash, required this.onUpdate});

  final CashInHand cash;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final amount = formatRupees(cash.balance.paise);
    final inAt = cash.lastInAt;
    final countAt = cash.lastCountAt;
    final detail = inAt != null && (countAt == null || inAt.isAfter(countAt))
        ? '${formatRupees(cash.lastInPaise!)} from ATM · ${shortDay(inAt)}'
        : countAt != null
        ? 'Counted ${shortDay(countAt)}'
        : 'Count your wallet to set it';
    return Semantics(
      container: true,
      label: 'Cash in hand, $amount',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: 14),
        decoration: BoxDecoration(
          color: c.cashTint,
          borderRadius: BorderRadius.circular(LoopdRadius.cardLarge),
          border: Border.all(color: c.line),
        ),
        child: Row(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 44,
                height: 30,
                decoration: BoxDecoration(color: c.cash, borderRadius: BorderRadius.circular(6)),
                child: Icon(Icons.payments_outlined, size: 20, color: c.onAccent),
              ),
            ),
            const SizedBox(width: LoopdSpace.md),
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LoopdType.title.copyWith(
                        color: c.textPrimary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (detail.isNotEmpty) ...[
                      const SizedBox(height: LoopdSpace.xxs),
                      Text(
                        detail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: LoopdType.caption.copyWith(color: c.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: LoopdSpace.md),
            LoopdPressable(
              onTap: onUpdate,
              label: 'Update cash',
              child: Container(
                height: LoopdSize.minTouch,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(LoopdRadius.pill),
                  border: Border.all(color: c.cash, width: 1.5),
                ),
                child: Text('Update cash', style: LoopdType.small.copyWith(color: c.cash)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bank accounts on one card, with hairlines between rows.
class _BankList extends StatelessWidget {
  const _BankList({required this.banks, required this.spending});

  final List<LedgerAccount> banks;
  final Map<String, int> spending;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(LoopdRadius.cardLarge),
        border: Border.all(color: c.line),
      ),
      child: Column(
        children: [
          for (final (index, bank) in banks.indexed) ...[
            if (index > 0) Divider(height: 1, thickness: 1, color: c.line),
            _BankRow(bank: bank, spent: spending[bank.id] ?? 0),
          ],
        ],
      ),
    );
  }
}

class _BankRow extends StatelessWidget {
  const _BankRow({required this.bank, required this.spent});

  final LedgerAccount bank;
  final int spent;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final amount = formatRupees(spent);
    return LoopdPressable(
      onTap: () => showAccountOptionsSheet(context, bank),
      label: '${bank.nickname}${bank.isDefault ? ', default' : ''}, ${bank.bankAndDigits}, $amount this month',
      pressedScale: 0.99,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.lg, vertical: 10),
          child: Row(
            children: [
              SizedBox(width: 44, child: LoopdMiniCard(color: bankColour(bank.bankName, c))),
              const SizedBox(width: LoopdSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            bank.nickname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: LoopdType.bodyStrong.copyWith(color: c.textPrimary),
                          ),
                        ),
                        if (bank.isDefault) ...[
                          const SizedBox(width: LoopdSpace.sm),
                          AccountTag.defaultFor(AccountKind.bank, c),
                        ],
                      ],
                    ),
                    const SizedBox(height: LoopdSpace.xxs),
                    Text(
                      bank.bankAndDigits,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LoopdType.caption.copyWith(color: c.textMuted, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LoopdSpace.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(amount, style: LoopdType.amount.copyWith(color: c.textPrimary)),
                  Text('this month', style: LoopdType.micro.copyWith(color: c.textMuted)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Default pill next to a nickname: green on a bank row; on a card
/// face, solid white with the card's colour, so it stands out on any bank.
/// A credit card drawn as a card in its bank's colour.
class _CreditCard extends StatelessWidget {
  const _CreditCard({required this.card, required this.spent});

  final LedgerAccount card;
  final int spent;

  static const _white = Color(0xFFFFFFFF);

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final amount = formatRupees(spent);
    final colour = bankColour(card.bankName, c);
    return LoopdPressable(
      onTap: () => showAccountOptionsSheet(context, card),
      label:
          '${card.nickname}${card.isDefault ? ', default' : ''}, ${card.bankName ?? ''} '
          'card ending ${card.last4 ?? ''}, $amount this month',
      child: Container(
        height: 104,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: colour, borderRadius: BorderRadius.circular(LoopdRadius.card)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.bankName ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LoopdType.caption.copyWith(color: _white),
            ),
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          card.nickname,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LoopdType.heading.copyWith(color: _white, fontSize: 18),
                        ),
                      ),
                      if (card.isDefault) ...[const SizedBox(width: LoopdSpace.sm), AccountTag.onCard(colour)],
                    ],
                  ),
                ),
                const SizedBox(width: LoopdSpace.md),
                Text(amount, style: LoopdType.amount.copyWith(color: _white)),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    '•••• ${card.last4 ?? ''}',
                    style: LoopdType.code.copyWith(color: _white, fontWeight: FontWeight.w600, letterSpacing: 1),
                  ),
                ),
                Text('this month', style: LoopdType.micro.copyWith(color: _white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
