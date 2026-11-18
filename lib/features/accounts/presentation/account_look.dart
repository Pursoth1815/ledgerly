import 'package:flutter/widgets.dart';

import '../../../core/ledger/banks.dart';
import '../../../core/ledger/ledger_types.dart';
import '../../../design_system/loopd_colors.dart';

/// The card colour of a listed bank, or the blank grey for one typed by hand.
Color bankColour(String? bankName, LoopdColors colors) {
  final bank = bankNamed(bankName);
  return bank == null ? colors.cardBlank : Color(bank.colour);
}

extension LedgerAccountLook on LedgerAccount {
  /// "HDFC Bank ••8124", as under each bank account.
  String get bankAndDigits => [?bankName, if (last4 != null) '••$last4'].join(' ');
}
