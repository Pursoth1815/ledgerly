import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/app_database.dart';
import '../errors/app_exception.dart';
import 'ledger_dao.dart';
import 'ledger_defaults.dart';
import 'ledger_rules.dart';
import 'ledger_types.dart';

part 'ledger_engine.g.dart';

/// A balance as the ledger knows it (proposal section 13). With a starting
/// point (an opening balance, or an Update count of Cash in hand) it is the
/// tracked balance; without one it is only the movement since tracking
/// began.
class AccountBalance {
  const AccountBalance({required this.paise, this.openingAsOf});

  /// In the ledger's sign: positive is money held or owed to you; a card's
  /// negative is the amount owed.
  final int paise;

  /// When the starting point was set.
  final DateTime? openingAsOf;

  bool get hasOpening => openingAsOf != null;
}

/// Cash in hand as Accounts and cards shows it.
class CashInHand {
  const CashInHand({required this.balance, this.lastInPaise, this.lastInAt});

  /// Before the first count this starts from ₹0 and follows what is
  /// recorded; each count sets it again.
  final AccountBalance balance;

  /// The latest Update count.
  DateTime? get lastCountAt => balance.openingAsOf;

  /// The latest money moved in from a bank, such as an ATM withdrawal.
  final int? lastInPaise;
  final DateTime? lastInAt;
}

/// Every money movement goes through here (ADR 0006): expenses, refunds,
/// income, transfers (including ATM withdrawals into Cash in hand), card
/// settlements and Update count. Modules never write money rows
/// themselves, so the totals cannot disagree.
///
/// Each command checks the posting shape for its kind, writes in one
/// database transaction, and keeps a revision with a full snapshot.
class LedgerEngine {
  LedgerEngine(this._db, {DateTime Function()? clock, Random? random})
    : _dao = LedgerDao(_db),
      _clock = clock ?? DateTime.now,
      _random = random ?? Random.secure();

  final AppDatabase _db;
  final LedgerDao _dao;
  final DateTime Function() _clock;
  final Random _random;

  int get _now => _clock().toUtc().millisecondsSinceEpoch;

  String _newId() => List.generate(16, (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();

  // --- Set-up -------------------------------------------------------------

  /// Creates Cash in hand, the bookkeeping accounts and the twelve default
  /// categories, if they are missing. Safe to run on every start.
  Future<void> ensureDefaults() => _db.transaction(() async {
    final now = _now;
    Future<void> system(String id, AccountKind kind, String name) => _db
        .into(_db.accounts)
        .insert(
          AccountsCompanion.insert(id: id, kind: kind.db, name: name, createdAt: now),
          mode: InsertMode.insertOrIgnore,
        );
    await system(SystemAccounts.cash, AccountKind.cash, 'Cash in hand');
    await system(SystemAccounts.adjustment, AccountKind.adjustment, 'Adjustments');
    await system(SystemAccounts.opening, AccountKind.opening, 'Opening balances');
    await system(SystemAccounts.income, AccountKind.income, 'Income');
    // A default added in a later version (Misc) joins an existing install
    // after the categories already there.
    for (final (id, name, colour, icon) in defaultCategories) {
      if (await _dao.getAccount(id) != null) continue;
      await system(id, AccountKind.category, name);
      final order = await _dao.lastCategoryOrder() + 1;
      await _db
          .into(_db.categories)
          .insert(CategoriesCompanion.insert(accountId: id, colour: colour, icon: icon, sortOrder: order));
    }
  });

  // --- Accounts and categories -------------------------------------------

  /// Adds a bank account (used for UPI) or a credit card. It becomes the
  /// default of its kind only when [makeDefault] is set; there may be none.
  ///
  /// [last4], when given, must be four digits. The same four digits cannot
  /// be saved twice among bank accounts, or twice among cards, whatever the
  /// bank (owner, 18 Nov 2026). A bank account and a card may share them.
  Future<String> addAccount({
    required AccountKind kind,
    required String name,
    String? bankName,
    String? bankCode,
    String? last4,
    bool makeDefault = false,
  }) async {
    if (kind != AccountKind.bank && kind != AccountKind.creditCard) {
      throw const LedgerException(LedgerFailure.invalidAccount);
    }
    final nickname = name.trim();
    final bank = bankName?.trim();
    if (nickname.isEmpty || (bank != null && bank.isEmpty)) throw const LedgerException(LedgerFailure.invalidAccount);
    if (last4 != null && !RegExp(r'^\d{4}$').hasMatch(last4)) {
      throw const LedgerException(LedgerFailure.invalidAccount);
    }
    return _db.transaction(() async {
      final existing = await _dao.activeAccounts(kind);
      if (last4 != null && existing.any((a) => a.last4 == last4)) {
        throw const LedgerException(LedgerFailure.duplicateAccount);
      }
      final id = _newId();
      if (makeDefault) await _clearDefault(kind);
      await _db
          .into(_db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: id,
              kind: kind.db,
              name: nickname,
              bankName: Value(bank),
              bankCode: Value(bankCode),
              last4: Value(last4),
              isDefault: Value(makeDefault),
              createdAt: _now,
            ),
          );
      return id;
    });
  }

  /// Makes [accountId] the one default of its kind.
  Future<void> setDefault(String accountId) => _db.transaction(() async {
    final account = await _dao.getAccount(accountId) ?? (throw const LedgerException(LedgerFailure.notFound));
    if (account.removedAt != null) throw const LedgerException(LedgerFailure.accountRemoved);
    await _clearDefault(AccountKind.fromDb(account.kind));
    await (_db.update(
      _db.accounts,
    )..where((a) => a.id.equals(accountId))).write(const AccountsCompanion(isDefault: Value(true)));
  });

  Future<void> _clearDefault(AccountKind kind) => (_db.update(
    _db.accounts,
  )..where((a) => a.kind.equals(kind.db))).write(const AccountsCompanion(isDefault: Value(false)));

  /// Removes an account or card. Its past transactions stay, under the name
  /// they were saved with; there is no archived state. Removing the default
  /// leaves no default until you choose one.
  Future<void> removeAccount(String accountId) async {
    if (SystemAccounts.all.contains(accountId)) throw const LedgerException(LedgerFailure.systemAccount);
    await _db.transaction(() async {
      final account = await _dao.getAccount(accountId) ?? (throw const LedgerException(LedgerFailure.notFound));
      if (account.removedAt != null) return;
      await (_db.update(_db.accounts)..where((a) => a.id.equals(account.id))).write(
        AccountsCompanion(removedAt: Value(_now), isDefault: const Value(false)),
      );
    });
  }

  /// The longest category name, so it fits a chip in the expense form.
  static const categoryNameMax = 20;

  /// The colours in the category palette, 0 to 24: one for each icon.
  static const categoryColours = 25;

  /// The most categories there can be: each needs a colour and an icon of
  /// its own, and there are twenty-five of each (owner, 18 Nov 2026).
  static const categoryMax = categoryColours;

  /// Adds a category with a name, a colour (0 to 24) and an icon. It goes
  /// last in the list. Names are unique, ignoring case and spaces, and no
  /// two categories share a colour or an icon (owner, 18 Nov 2026), so there
  /// are at most [categoryMax].
  Future<String> addCategory({required String name, required int colour, required String icon}) =>
      _db.transaction(() async {
        final count = (await _dao.activeAccounts(AccountKind.category)).length;
        if (count >= categoryMax) throw const LedgerException(LedgerFailure.categoryLimit);
        final clean = await _checkCategory(name, colour, icon);
        final id = _newId();
        final last = await _dao.lastCategoryOrder();
        await _db
            .into(_db.accounts)
            .insert(AccountsCompanion.insert(id: id, kind: AccountKind.category.db, name: clean, createdAt: _now));
        await _db
            .into(_db.categories)
            .insert(CategoriesCompanion.insert(accountId: id, colour: colour, icon: icon, sortOrder: last + 1));
        return id;
      });

  /// Renames, recolours or changes the icon of a category. Its past
  /// expenses move with it, because they point at the category, not its name.
  Future<void> updateCategory(String accountId, {String? name, int? colour, String? icon}) => _db.transaction(() async {
    final row = await _dao.getAccount(accountId);
    if (row == null || row.kind != AccountKind.category.db) throw const LedgerException(LedgerFailure.notFound);
    final current = await (_db.select(_db.categories)..where((c) => c.accountId.equals(accountId))).getSingle();
    final clean = await _checkCategory(
      name ?? row.name,
      colour ?? current.colour,
      icon ?? current.icon,
      except: accountId,
    );
    await (_db.update(_db.accounts)..where((a) => a.id.equals(accountId))).write(AccountsCompanion(name: Value(clean)));
    await (_db.update(_db.categories)..where((c) => c.accountId.equals(accountId))).write(
      CategoriesCompanion(
        colour: colour == null ? const Value.absent() : Value(colour),
        icon: icon == null ? const Value.absent() : Value(icon),
      ),
    );
  });

  /// How many live expenses use any of [categoryIds], all time.
  Future<int> countCategoryExpenses(Iterable<String> categoryIds) async =>
      (await _dao.liveTransactionsOn(categoryIds)).where((t) => t.kind == TransactionKind.expense.db).length;

  /// Deletes categories the owner added, after moving their expenses and
  /// refunds to [moveTo] (Misc unless they choose another). Each moved one
  /// gets an edit revision, as if recategorised by hand. The category is
  /// removed like an account, so deleted transactions keep pointing at it;
  /// its colour and icon are free again. Default categories cannot be
  /// deleted.
  Future<void> deleteCategories(Iterable<String> categoryIds, {String moveTo = miscCategoryId}) =>
      _db.transaction(() async {
        final ids = categoryIds.toSet();
        if (ids.isEmpty) return;
        if (ids.any(defaultCategoryIds.contains) || ids.contains(moveTo)) {
          throw const LedgerException(LedgerFailure.builtInCategory);
        }
        for (final id in {...ids, moveTo}) {
          final row = await _dao.getAccount(id);
          if (row == null || row.kind != AccountKind.category.db || row.removedAt != null) {
            throw const LedgerException(LedgerFailure.notFound);
          }
        }
        // Purchases first: a refund must follow its purchase's category.
        final moving = await _dao.liveTransactionsOn(ids);
        moving.sort(
          (a, b) => (a.kind == TransactionKind.refund.db ? 1 : 0) - (b.kind == TransactionKind.refund.db ? 1 : 0),
        );
        for (final row in {for (final t in moving) t.id: t}.values) {
          final postings = await _dao.getPostings(row.id);
          final moved = <String, int>{};
          for (final MapEntry(key: account, value: paise) in postings.entries) {
            final to = ids.contains(account) ? moveTo : account;
            moved[to] = (moved[to] ?? 0) + paise;
          }
          await _write(row.id, _entryOf(row, postings).withPostings(moved), action: 'edit', existing: row);
        }
        await (_db.delete(_db.categories)..where((c) => c.accountId.isIn(ids))).go();
        await (_db.update(_db.accounts)..where((a) => a.id.isIn(ids))).write(AccountsCompanion(removedAt: Value(_now)));
      });

  /// Checks a category's name, colour and icon against the others, and
  /// returns the name with spaces tidied. The table's unique keys back this
  /// up.
  Future<String> _checkCategory(String name, int colour, String icon, {String? except}) async {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.isEmpty ||
        clean.length > categoryNameMax ||
        colour < 0 ||
        colour >= categoryColours ||
        icon.trim().isEmpty) {
      throw const LedgerException(LedgerFailure.invalidCategory);
    }
    final others = await _dao.activeAccounts(AccountKind.category);
    if (others.any((a) => a.id != except && a.name.toLowerCase() == clean.toLowerCase())) {
      throw const LedgerException(LedgerFailure.duplicateCategory);
    }
    final looks = await _db.select(_db.categories).get();
    if (looks.any((k) => k.accountId != except && (k.colour == colour || k.icon == icon))) {
      throw const LedgerException(LedgerFailure.categoryLookTaken);
    }
    return clean;
  }

  // --- Money ---------------------------------------------------------------

  /// An expense: the category goes up, the funding account goes down. The
  /// method must fit the account (UPI → bank, Credit Card → card, Cash →
  /// Cash in hand). A card paid by UPI QR is [PaymentMethod.creditCard] with
  /// channel `upi_qr`.
  Future<String> recordExpense({
    required int amountPaise,
    required PaymentMethod method,
    required String fundingAccountId,
    required String categoryId,
    required DateTime occurredAt,
    String? merchant,
    String? note,
    String? channel,
  }) => _create(
    _expenseEntry(
      amountPaise: amountPaise,
      method: method,
      fundingAccountId: fundingAccountId,
      categoryId: categoryId,
      occurredAt: occurredAt,
      merchant: merchant,
      note: note,
      channel: channel,
    ),
  );

  /// Changes an expense: method, account or card, category, amount, date,
  /// merchant or note. The id, its refunds and its SMS links stay.
  Future<void> editExpense(
    String id, {
    required int amountPaise,
    required PaymentMethod method,
    required String fundingAccountId,
    required String categoryId,
    required DateTime occurredAt,
    String? merchant,
    String? note,
    String? channel,
  }) => _replace(
    id,
    _expenseEntry(
      amountPaise: amountPaise,
      method: method,
      fundingAccountId: fundingAccountId,
      categoryId: categoryId,
      occurredAt: occurredAt,
      merchant: merchant,
      note: note,
      channel: channel,
    ),
    action: 'edit',
  );

  LedgerEntry _expenseEntry({
    required int amountPaise,
    required PaymentMethod method,
    required String fundingAccountId,
    required String categoryId,
    required DateTime occurredAt,
    String? merchant,
    String? note,
    String? channel,
  }) {
    _positive(amountPaise);
    return LedgerEntry(
      kind: TransactionKind.expense,
      method: method,
      channel: channel,
      occurredAt: occurredAt,
      merchant: merchant,
      note: note,
      postings: {categoryId: amountPaise, fundingAccountId: -amountPaise},
    );
  }

  /// A refund of [originalId]: the money comes back to [destinationAccountId]
  /// (the same card, a bank account or cash) and the original's category goes
  /// down. Refunds can never add up to more than the original.
  Future<String> recordRefund({
    required String originalId,
    required int amountPaise,
    required PaymentMethod method,
    required String destinationAccountId,
    required DateTime occurredAt,
    String? note,
  }) async {
    _positive(amountPaise);
    final original = await _dao.getTransaction(originalId);
    if (original == null || original.deletedAt != null || original.kind != TransactionKind.expense.db) {
      throw const LedgerException(LedgerFailure.refundWithoutOriginal);
    }
    final kinds = await _dao.accountKinds((await _dao.getPostings(originalId)).keys);
    final category = kinds.entries.firstWhere((entry) => entry.value == AccountKind.category).key;
    return _create(
      LedgerEntry(
        kind: TransactionKind.refund,
        method: method,
        occurredAt: occurredAt,
        note: note,
        merchant: original.merchant,
        refundOf: originalId,
        postings: {destinationAccountId: amountPaise, category: -amountPaise},
      ),
    );
  }

  /// Money received, such as salary, into a bank account or Cash in hand.
  /// Never mixed into spending.
  Future<String> recordIncome({
    required int amountPaise,
    required String toAccountId,
    required DateTime occurredAt,
    String incomeAccountId = SystemAccounts.income,
    String? source,
    String? note,
  }) {
    _positive(amountPaise);
    return _create(
      LedgerEntry(
        kind: TransactionKind.income,
        occurredAt: occurredAt,
        merchant: source,
        note: note,
        postings: {toAccountId: amountPaise, incomeAccountId: -amountPaise},
      ),
    );
  }

  /// Money moved between your own accounts. An ATM withdrawal is a transfer
  /// from a bank account to Cash in hand. Never spending.
  Future<String> recordTransfer({
    required int amountPaise,
    required String fromAccountId,
    required String toAccountId,
    required DateTime occurredAt,
    String? note,
  }) {
    _positive(amountPaise);
    if (fromAccountId == toAccountId) throw const LedgerException(LedgerFailure.wrongShape);
    return _create(
      LedgerEntry(
        kind: TransactionKind.transfer,
        occurredAt: occurredAt,
        note: note,
        postings: {toAccountId: amountPaise, fromAccountId: -amountPaise},
      ),
    );
  }

  /// Paying a credit card bill: a settlement, not an expense, because the
  /// purchases were counted when they were made.
  Future<String> recordCardPayment({
    required int amountPaise,
    required String fromBankId,
    required String cardId,
    required DateTime occurredAt,
    String? note,
  }) {
    _positive(amountPaise);
    return _create(
      LedgerEntry(
        kind: TransactionKind.cardPayment,
        occurredAt: occurredAt,
        note: note,
        postings: {cardId: amountPaise, fromBankId: -amountPaise},
      ),
    );
  }

  /// Update count: you type what is really in your wallet, and that is Cash
  /// in hand from then on. A new count replaces the last one.
  ///
  /// Anything dated after the count changes Cash in hand as usual. Anything
  /// dated before it is already in the count, even when it is recorded
  /// later, such as an ATM SMS read after you counted. A count is not
  /// spending or income, so it writes no money row: it is kept as a
  /// checkpoint ([CheckpointSource.count]), and ₹0 is a valid count.
  Future<void> countCash(int actualPaise, {DateTime? at}) async {
    if (actualPaise < 0) throw const LedgerException(LedgerFailure.invalidAmount);
    await _checkpoint(SystemAccounts.cash, actualPaise, asOf: at ?? _clock(), source: CheckpointSource.count);
  }

  /// An optional opening balance, as of a day you choose. The tracked
  /// balance is the opening balance plus everything dated after it.
  Future<String> setOpeningBalance(String accountId, int paise, {required DateTime asOf}) {
    if (paise == 0) throw const LedgerException(LedgerFailure.invalidAmount);
    return _create(
      LedgerEntry(
        kind: TransactionKind.openingBalance,
        occurredAt: asOf,
        postings: {accountId: paise, SystemAccounts.opening: -paise},
      ),
    );
  }

  /// A balance you checked in your bank or card app, in the ledger's sign:
  /// a card's amount owed is negative.
  Future<String> addCheckpoint(String accountId, int actualPaise, {required DateTime asOf, String? note}) =>
      _checkpoint(accountId, actualPaise, asOf: asOf, source: CheckpointSource.manual, note: note);

  Future<String> _checkpoint(
    String accountId,
    int actualPaise, {
    required DateTime asOf,
    required String source,
    String? note,
  }) async {
    final id = _newId();
    await _db
        .into(_db.balanceCheckpoints)
        .insert(
          BalanceCheckpointsCompanion.insert(
            id: id,
            accountId: accountId,
            asOf: asOf.toUtc().millisecondsSinceEpoch,
            actualPaise: actualPaise,
            source: source,
            note: Value(note),
            createdAt: _now,
          ),
        );
    return id;
  }

  // --- Delete and undo -------------------------------------------------------

  /// Soft-deletes a transaction. A purchase with live refunds is deleted only
  /// together with them, as an explicit choice ([withRefunds]).
  Future<void> delete(String id, {bool withRefunds = false}) => _db.transaction(() async {
    final row = await _dao.getTransaction(id) ?? (throw const LedgerException(LedgerFailure.notFound));
    if (row.deletedAt != null) return;
    final refunds = await _dao.activeRefunds(id);
    if (refunds.isNotEmpty && !withRefunds) throw const LedgerException(LedgerFailure.hasLiveRefunds);
    final operation = _newId();
    for (final refund in refunds) {
      await _setDeleted(refund, deleted: true, operation: operation);
    }
    await _setDeleted(row, deleted: true, operation: operation);
  });

  /// Undoes the latest change to a transaction by applying the snapshot
  /// before it, as a new revision. Works only while nothing has changed since
  /// [expectedRevision] (the revision the person saw).
  Future<void> undo(String id, {required int expectedRevision}) => _db.transaction(() async {
    final row = await _dao.getTransaction(id) ?? (throw const LedgerException(LedgerFailure.notFound));
    if (row.revision != expectedRevision) throw const LedgerException(LedgerFailure.changedSince);
    if (expectedRevision == 1) {
      // Undoing the creation removes it again.
      if ((await _dao.activeRefunds(id)).isNotEmpty) throw const LedgerException(LedgerFailure.hasLiveRefunds);
      await _setDeleted(row, deleted: true, action: 'undo');
      return;
    }
    final previous =
        await _dao.getRevision(id, expectedRevision - 1) ?? (throw const LedgerException(LedgerFailure.notFound));
    final snapshot = _Snapshot.fromJson(previous.snapshotJson);
    if (snapshot.deleted) {
      await _setDeleted(row, deleted: true, action: 'undo');
    } else {
      await _write(id, snapshot.entry, action: 'undo', existing: row);
    }
  });

  // --- Reading ---------------------------------------------------------------

  /// The account's balance in the ledger's sign. From a starting point (the
  /// latest opening balance or Update count, whichever is later), only what
  /// is dated after it counts, so older history does not count twice.
  Future<AccountBalance> balanceOf(String accountId) async {
    DateTime utc(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    final opening = await _dao.getOpeningBalance(accountId);
    final count = await _dao.latestCount(accountId);
    if (count != null && (opening == null || count.asOf >= opening.occurredAt)) {
      final after = await _dao.accountTotal(accountId, after: count.asOf, createdFrom: count.createdAt);
      return AccountBalance(paise: count.actualPaise + after, openingAsOf: utc(count.asOf));
    }
    if (opening == null) return AccountBalance(paise: await _dao.accountTotal(accountId));
    final openingPaise = (await _dao.getPostings(opening.id))[accountId]!;
    final after = await _dao.accountTotal(
      accountId,
      after: opening.occurredAt,
      createdFrom: opening.createdAt,
      excluding: opening.id,
    );
    return AccountBalance(paise: openingPaise + after, openingAsOf: utc(opening.occurredAt));
  }

  /// The bank accounts or credit cards that are not removed, oldest first, as
  /// they change.
  Stream<List<LedgerAccount>> watchAccounts(AccountKind kind) => _dao
      .watchActiveAccounts(kind)
      .map(
        (rows) => [
          for (final row in rows)
            LedgerAccount(
              id: row.id,
              kind: kind,
              nickname: row.name,
              bankName: row.bankName,
              bankCode: row.bankCode,
              last4: row.last4,
              isDefault: row.isDefault,
            ),
        ],
      );

  /// The expense categories that are not removed, in their sheet order, as
  /// they change.
  Stream<List<LedgerCategory>> watchCategories() => _dao.watchActiveCategories().map(
    (rows) => [
      for (final (account, category) in rows)
        LedgerCategory(
          id: account.id,
          name: account.name,
          colour: category.colour,
          icon: category.icon,
          builtIn: defaultCategoryIds.contains(account.id),
        ),
    ],
  );

  /// An expense to edit, or null when it is missing, deleted or not an
  /// expense.
  Future<ExpenseRecord?> getExpense(String id) async {
    final row = await _dao.getTransaction(id);
    if (row == null || row.deletedAt != null || row.kind != TransactionKind.expense.db) return null;
    final postings = await _dao.getPostings(id);
    final kinds = await _dao.accountKinds(postings.keys);
    String? accountWhere(bool Function(AccountKind kind) test) =>
        postings.keys.where((account) => test(kinds[account]!)).firstOrNull;
    final category = accountWhere((kind) => kind == AccountKind.category);
    final funding = accountWhere((kind) => kind.holdsMoney);
    if (category == null || funding == null) return null;
    return ExpenseRecord(
      id: id,
      revision: row.revision,
      amountPaise: postings[category]!,
      method: PaymentMethod.fromDb(row.paymentMethod!),
      fundingAccountId: funding,
      categoryId: category,
      occurredAt: DateTime.fromMillisecondsSinceEpoch(row.occurredAt, isUtc: true).toLocal(),
      channel: row.channel,
      merchant: row.merchant,
      note: row.note,
    );
  }

  /// One bank account or card, removed or not, as screens show it. An
  /// expense can still point at a removed one.
  Future<LedgerAccount?> getAccount(String id) async {
    final row = await _dao.getAccount(id);
    if (row == null) return null;
    return LedgerAccount(
      id: row.id,
      kind: AccountKind.fromDb(row.kind),
      nickname: row.name,
      bankName: row.bankName,
      bankCode: row.bankCode,
      last4: row.last4,
      isDefault: row.isDefault,
    );
  }

  /// What was spent in each category in the calendar month of [month]
  /// (local time), net of refunds of those purchases: category id → paise.
  /// Categories with nothing spent are left out.
  Stream<Map<String, int>> watchCategorySpending(DateTime month) {
    final (from, to) = _monthRange(month);
    return _dao.watchLedgerChanges().asyncMap((_) => _dao.categorySpending(from, to));
  }

  /// What each bank account, card and Cash in hand spent in the calendar
  /// month of [month] (local time), net of refunds of those purchases:
  /// account id → paise. Accounts with no spending are left out.
  Stream<Map<String, int>> watchMonthSpending(DateTime month) {
    final (from, to) = _monthRange(month);
    return _dao.watchLedgerChanges().asyncMap((_) => _dao.spendingByFunding(from, to));
  }

  /// The first local day of [month] and of the month after, as YYYY-MM-DD.
  static (String, String) _monthRange(DateTime month) {
    String day(int year, int m) => '${year + (m - 1) ~/ 12}-${((m - 1) % 12 + 1).toString().padLeft(2, '0')}-01';
    return (day(month.year, month.month), day(month.year, month.month + 1));
  }

  /// Cash in hand for the top of Accounts and cards, as it changes.
  Stream<CashInHand> watchCashInHand() => _dao.watchLedgerChanges().asyncMap((_) async {
    DateTime? time(int? ms) => ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    final withdrawal = await _dao.lastTransferInto(SystemAccounts.cash);
    return CashInHand(
      balance: await balanceOf(SystemAccounts.cash),
      lastInPaise: withdrawal?.$1,
      lastInAt: time(withdrawal?.$2),
    );
  });

  /// Checks every live transaction against the rules: shapes, sums, methods
  /// and refund limits. Returns one line per problem; empty when healthy.
  /// Runs in tests, on debug starts and after restores.
  Future<List<String>> healthCheck() async {
    final problems = <String>[];
    final kinds = await _dao.allAccountKinds();
    final postings = await _dao.allPostings();
    final live = await _dao.activeTransactions();
    final refunded = <String, int>{};
    for (final row in live) {
      final entry = _entryOf(row, postings[row.id] ?? const {});
      try {
        checkEntry(entry, kinds);
      } on LedgerException catch (error) {
        problems.add('${row.id} ${error.code}');
        continue;
      }
      if (entry.kind == TransactionKind.refund) {
        refunded.update(
          row.refundOf!,
          (sum) => sum + refundAmount(entry.postings, kinds),
          ifAbsent: () => refundAmount(entry.postings, kinds),
        );
      }
    }
    final byId = {for (final row in live) row.id: row};
    for (final MapEntry(key: originalId, value: total) in refunded.entries) {
      final original = byId[originalId];
      if (original == null) {
        problems.add('$originalId ${const LedgerException(LedgerFailure.refundWithoutOriginal).code}');
      } else if (total > expenseAmount(postings[originalId]!, kinds)) {
        problems.add('$originalId ${const LedgerException(LedgerFailure.refundExceedsOriginal).code}');
      }
    }
    return problems;
  }

  // --- Writing ---------------------------------------------------------------

  void _positive(int paise) {
    if (paise <= 0) throw const LedgerException(LedgerFailure.invalidAmount);
  }

  Future<String> _create(LedgerEntry entry) => _db.transaction(() async {
    final id = _newId();
    await _write(id, entry, action: 'create');
    return id;
  });

  Future<void> _replace(String id, LedgerEntry entry, {required String action}) => _db.transaction(() async {
    final existing = await _dao.getTransaction(id) ?? (throw const LedgerException(LedgerFailure.notFound));
    if (existing.kind != entry.kind.db) throw const LedgerException(LedgerFailure.wrongShape);
    await _write(id, entry, action: action, existing: existing);
  });

  /// Checks [entry], then writes the transaction, its postings and a
  /// revision. The caller holds a database transaction.
  Future<void> _write(String id, LedgerEntry entry, {required String action, LedgerTransaction? existing}) async {
    final kinds = await _dao.accountKinds(entry.postings.keys);
    checkEntry(entry, kinds);
    if (existing == null) {
      for (final accountId in entry.postings.keys) {
        if ((await _dao.getAccount(accountId))?.removedAt != null) {
          throw const LedgerException(LedgerFailure.accountRemoved);
        }
      }
    }
    if (entry.kind == TransactionKind.refund) await _checkRefundLimit(id, entry, kinds);
    if (entry.kind == TransactionKind.expense && existing != null) {
      // An edited purchase can never fall below what was already refunded.
      var refunded = 0;
      for (final refund in await _dao.activeRefunds(id)) {
        final postings = await _dao.getPostings(refund.id);
        refunded += refundAmount(postings, await _dao.accountKinds(postings.keys));
      }
      if (refunded > expenseAmount(entry.postings, kinds)) {
        throw const LedgerException(LedgerFailure.refundExceedsOriginal);
      }
    }
    final oldPostings = existing == null ? const <String, int>{} : await _dao.getPostings(id);

    final now = _now;
    final occurredAt = entry.occurredAt.toUtc().millisecondsSinceEpoch;
    final revision = (existing?.revision ?? 0) + 1;
    final companion = LedgerTransactionsCompanion(
      id: Value(id),
      kind: Value(entry.kind.db),
      paymentMethod: Value(entry.method?.db),
      channel: Value(entry.channel),
      occurredAt: Value(occurredAt),
      localDate: Value(_localDate(entry.occurredAt)),
      merchant: Value(entry.merchant),
      note: Value(entry.note),
      refundOf: Value(entry.refundOf),
      revision: Value(revision),
      createdAt: Value(existing?.createdAt ?? now),
      updatedAt: Value(now),
      deletedAt: const Value(null),
    );
    await _db.into(_db.ledgerTransactions).insertOnConflictUpdate(companion);
    await _dao.savePostings(id, entry.postings, _newId);
    await _revision(id, revision, action, _Snapshot(entry, deleted: false));

    // Anything dated before a checked balance marks that check for a recheck.
    final earliest = existing == null ? occurredAt : min(occurredAt, existing.occurredAt);
    await _dao.markChecksStale({...entry.postings.keys, ...oldPostings.keys}, earliest);
  }

  Future<void> _checkRefundLimit(String id, LedgerEntry entry, Map<String, AccountKind> kinds) async {
    final original = await _dao.getTransaction(entry.refundOf!);
    if (original == null || original.deletedAt != null || original.kind != TransactionKind.expense.db) {
      throw const LedgerException(LedgerFailure.refundWithoutOriginal);
    }
    final originalPostings = await _dao.getPostings(original.id);
    final originalKinds = await _dao.accountKinds(originalPostings.keys);
    // The refund must reduce the original's own category.
    final category = originalKinds.entries.firstWhere((entry) => entry.value == AccountKind.category).key;
    if ((entry.postings[category] ?? 0) >= 0) throw const LedgerException(LedgerFailure.wrongShape);
    var total = refundAmount(entry.postings, kinds);
    for (final other in await _dao.activeRefunds(original.id, excluding: id)) {
      final postings = await _dao.getPostings(other.id);
      total += refundAmount(postings, await _dao.accountKinds(postings.keys));
    }
    if (total > expenseAmount(originalPostings, originalKinds)) {
      throw const LedgerException(LedgerFailure.refundExceedsOriginal);
    }
  }

  Future<void> _setDeleted(
    LedgerTransaction row, {
    required bool deleted,
    String action = 'delete',
    String? operation,
  }) async {
    final revision = row.revision + 1;
    await (_db.update(_db.ledgerTransactions)..where((t) => t.id.equals(row.id))).write(
      LedgerTransactionsCompanion(
        deletedAt: Value(deleted ? _now : null),
        revision: Value(revision),
        updatedAt: Value(_now),
      ),
    );
    final postings = await _dao.getPostings(row.id);
    await _revision(
      row.id,
      revision,
      action,
      _Snapshot(_entryOf(row, postings), deleted: deleted),
      operation: operation,
    );
    await _dao.markChecksStale(postings.keys, row.occurredAt);
  }

  Future<void> _revision(String id, int revision, String action, _Snapshot snapshot, {String? operation}) => _db
      .into(_db.transactionRevisions)
      .insert(
        TransactionRevisionsCompanion.insert(
          transactionId: id,
          revision: revision,
          action: action,
          snapshotJson: snapshot.toJson(),
          operationId: Value(operation),
          changedAt: _now,
        ),
      );

  LedgerEntry _entryOf(LedgerTransaction row, Map<String, int> postings) => LedgerEntry(
    kind: TransactionKind.fromDb(row.kind),
    method: row.paymentMethod == null ? null : PaymentMethod.fromDb(row.paymentMethod!),
    channel: row.channel,
    occurredAt: DateTime.fromMillisecondsSinceEpoch(row.occurredAt, isUtc: true),
    merchant: row.merchant,
    note: row.note,
    refundOf: row.refundOf,
    postings: postings,
  );

  static String _localDate(DateTime at) {
    final local = at.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }
}

/// A full snapshot of a transaction, kept with every revision.
class _Snapshot {
  _Snapshot(this.entry, {required this.deleted});

  factory _Snapshot.fromJson(String text) {
    final json = jsonDecode(text) as Map<String, dynamic>;
    return _Snapshot(
      LedgerEntry(
        kind: TransactionKind.fromDb(json['kind'] as String),
        method: json['method'] == null ? null : PaymentMethod.fromDb(json['method'] as String),
        channel: json['channel'] as String?,
        occurredAt: DateTime.fromMillisecondsSinceEpoch(json['occurredAt'] as int, isUtc: true),
        merchant: json['merchant'] as String?,
        note: json['note'] as String?,
        refundOf: json['refundOf'] as String?,
        postings: (json['postings'] as Map<String, dynamic>).map((key, value) => MapEntry(key, value as int)),
      ),
      deleted: json['deleted'] as bool,
    );
  }

  final LedgerEntry entry;
  final bool deleted;

  String toJson() => jsonEncode({
    'kind': entry.kind.db,
    'method': entry.method?.db,
    'channel': entry.channel,
    'occurredAt': entry.occurredAt.toUtc().millisecondsSinceEpoch,
    'merchant': entry.merchant,
    'note': entry.note,
    'refundOf': entry.refundOf,
    'postings': entry.postings,
    'deleted': deleted,
  });
}

/// The ledger engine, shared by every feature that moves money.
@Riverpod(keepAlive: true)
LedgerEngine ledgerEngine(Ref ref) => LedgerEngine(ref.watch(appDatabaseProvider));
