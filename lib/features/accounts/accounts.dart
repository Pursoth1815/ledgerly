/// Accounts and cards, the wallet (proposal section 4). Public file of
/// the feature.
///
/// Other features may use the reads here: the live lists of accounts and
/// cards, and how an account looks. Opening the Add sheet is a
/// write, so only `app/` uses [showAddAccountSheet] (architecture rule 3).
library;

export 'presentation/account_look.dart' show AccountTag, LedgerAccountLook, bankColour;
export 'presentation/accounts_sheet.dart' show AccountsSheet, ViewAccountExpenses, showAccountsSheet;
export 'presentation/add_account_sheet.dart' show showAddAccountSheet;
export 'presentation/providers/accounts_providers.dart' show accountsOfKindProvider;
