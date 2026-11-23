import 'package:flutter/widgets.dart';

import '../../features/accounts/accounts.dart';
import '../../features/expenses/expenses.dart';

/// Opens Accounts and cards. Its View expenses opens a list that belongs to
/// Expenses, so `app/` joins the two (architecture rule 3). More and the
/// Money tab both open it this way.
Future<void> openAccountsSheet(BuildContext context) => showAccountsSheet(
  context,
  onViewExpenses: (context, accountId) => showAccountExpensesSheet(
    context,
    accountId: accountId,
    onAddAccount: (context, kind) => showAddAccountSheet(context, kind: kind),
  ),
);
