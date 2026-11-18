import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/ledger/ledger_engine.dart';
import '../../../../core/ledger/ledger_types.dart';

part 'accounts_providers.g.dart';

// Live reads for Accounts and cards. Each one follows a watched query in the
// ledger engine, so a screen redraws by itself after any change; nothing here
// writes.

/// The bank accounts ([AccountKind.bank]) or cards ([AccountKind.creditCard])
/// that are not removed, oldest first.
@riverpod
Stream<List<LedgerAccount>> accountsOfKind(Ref ref, AccountKind kind) =>
    ref.watch(ledgerEngineProvider).watchAccounts(kind);

/// What each account, card and Cash in hand spent in [month]'s calendar
/// month: account id → paise.
@riverpod
Stream<Map<String, int>> monthSpending(Ref ref, DateTime month) =>
    ref.watch(ledgerEngineProvider).watchMonthSpending(month);

/// Cash in hand: the balance, the last count and the last money moved in.
@riverpod
Stream<CashInHand> cashInHand(Ref ref) => ref.watch(ledgerEngineProvider).watchCashInHand();
