import 'package:flutter/widgets.dart';

import '../../../core/ledger/banks.dart';
import '../../../core/ledger/ledger_types.dart';
import '../../../design_system/loopd_colors.dart';
import '../../../design_system/loopd_spacing.dart';
import '../../../design_system/loopd_typography.dart';

/// The card colour of a listed bank, or the blank grey for one typed by hand.
Color bankColour(String? bankName, LoopdColors colors) {
  final bank = bankNamed(bankName);
  return bank == null ? colors.cardBlank : Color(bank.colour);
}

extension LedgerAccountLook on LedgerAccount {
  /// "HDFC Bank ••8124", as under each bank account.
  String get bankAndDigits => [?bankName, if (last4 != null) '••$last4'].join(' ');
}

/// The small pill next to an account's nickname, such as "Default" (green
/// on a bank account, violet on a card) or "Removed". Accounts and cards and
/// the expense form use the same one.
class AccountTag extends StatelessWidget {
  const AccountTag({required this.label, required this.color, required this.tint, super.key});

  /// "Default" for a bank account (green) or a card (violet).
  factory AccountTag.defaultFor(AccountKind kind, LoopdColors c) => kind == AccountKind.creditCard
      ? AccountTag(label: 'Default', color: c.creditCard, tint: c.creditCardTint)
      : AccountTag(label: 'Default', color: c.money, tint: c.moneyTint);

  /// "Default" on a card face: white, with the card's own colour as text.
  factory AccountTag.onCard(Color cardColour) =>
      AccountTag(label: 'Default', color: cardColour, tint: const Color(0xFFFFFFFF));

  final String label;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: LoopdSpace.sm, vertical: LoopdSpace.xxs),
    decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(LoopdRadius.pill)),
    child: Text(
      label,
      style: LoopdType.micro.copyWith(color: color, fontWeight: FontWeight.w800),
    ),
  );
}
