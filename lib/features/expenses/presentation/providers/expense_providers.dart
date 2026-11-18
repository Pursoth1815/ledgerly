import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/ledger/ledger_engine.dart';
import '../../../../core/ledger/ledger_types.dart';

part 'expense_providers.g.dart';

// Live reads for the expense form. Writes go straight to the ledger engine.

/// The expense categories that are not removed, in their sheet order.
@riverpod
Stream<List<LedgerCategory>> expenseCategories(Ref ref) => ref.watch(ledgerEngineProvider).watchCategories();

/// What each category spent in [month]'s calendar month, net of refunds:
/// category id → paise.
@riverpod
Stream<Map<String, int>> categorySpending(Ref ref, DateTime month) =>
    ref.watch(ledgerEngineProvider).watchCategorySpending(month);

/// Spending from the local day [from] up to [to] (end excluded), for the
/// Money tab: purchases net of their refunds, and the refunds that came back.
@riverpod
Stream<SpendingReport> spending(Ref ref, DateTime from, DateTime to) =>
    ref.watch(ledgerEngineProvider).watchSpending(from, to);
