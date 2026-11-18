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
