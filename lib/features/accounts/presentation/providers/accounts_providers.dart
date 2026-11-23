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

/// This calendar month's spending, for the wallet's totals on each card.
@riverpod
Stream<SpendingReport> walletSpending(Ref ref, DateTime month) => ref
    .watch(ledgerEngineProvider)
    .watchSpending(DateTime(month.year, month.month), DateTime(month.year, month.month + 1));
