// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The expense categories that are not removed, in their sheet order.

@ProviderFor(expenseCategories)
final expenseCategoriesProvider = ExpenseCategoriesProvider._();

/// The expense categories that are not removed, in their sheet order.

final class ExpenseCategoriesProvider
    extends $FunctionalProvider<AsyncValue<List<LedgerCategory>>, List<LedgerCategory>, Stream<List<LedgerCategory>>>
    with $FutureModifier<List<LedgerCategory>>, $StreamProvider<List<LedgerCategory>> {
  /// The expense categories that are not removed, in their sheet order.
  ExpenseCategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expenseCategoriesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseCategoriesHash();

  @$internal
  @override
  $StreamProviderElement<List<LedgerCategory>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<LedgerCategory>> create(Ref ref) {
    return expenseCategories(ref);
  }
}

String _$expenseCategoriesHash() => r'665e7b972d86d780293bce9d6e1d83ac44ccebf2';

/// What each category spent in [month]'s calendar month, net of refunds:
/// category id → paise.

@ProviderFor(categorySpending)
final categorySpendingProvider = CategorySpendingFamily._();

/// What each category spent in [month]'s calendar month, net of refunds:
/// category id → paise.

final class CategorySpendingProvider
    extends $FunctionalProvider<AsyncValue<Map<String, int>>, Map<String, int>, Stream<Map<String, int>>>
    with $FutureModifier<Map<String, int>>, $StreamProvider<Map<String, int>> {
  /// What each category spent in [month]'s calendar month, net of refunds:
  /// category id → paise.
  CategorySpendingProvider._({required CategorySpendingFamily super.from, required DateTime super.argument})
    : super(
        retry: null,
        name: r'categorySpendingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categorySpendingHash();

  @override
  String toString() {
    return r'categorySpendingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, int>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, int>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return categorySpending(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CategorySpendingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$categorySpendingHash() => r'0aa775fd62e6e4a68567b2fd773ec5f927f2dac1';

/// What each category spent in [month]'s calendar month, net of refunds:
/// category id → paise.

final class CategorySpendingFamily extends $Family with $FunctionalFamilyOverride<Stream<Map<String, int>>, DateTime> {
  CategorySpendingFamily._()
    : super(
        retry: null,
        name: r'categorySpendingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// What each category spent in [month]'s calendar month, net of refunds:
  /// category id → paise.

  CategorySpendingProvider call(DateTime month) => CategorySpendingProvider._(argument: month, from: this);

  @override
  String toString() => r'categorySpendingProvider';
}

/// What has come back for one purchase, for Edit expense.

@ProviderFor(expenseRefunded)
final expenseRefundedProvider = ExpenseRefundedFamily._();

/// What has come back for one purchase, for Edit expense.

final class ExpenseRefundedProvider extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// What has come back for one purchase, for Edit expense.
  ExpenseRefundedProvider._({required ExpenseRefundedFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'expenseRefundedProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expenseRefundedHash();

  @override
  String toString() {
    return r'expenseRefundedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    final argument = this.argument as String;
    return expenseRefunded(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExpenseRefundedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expenseRefundedHash() => r'7a9f4caaf50065074e1c985b1dfa2c856beff149';

/// What has come back for one purchase, for Edit expense.

final class ExpenseRefundedFamily extends $Family with $FunctionalFamilyOverride<Stream<int>, String> {
  ExpenseRefundedFamily._()
    : super(
        retry: null,
        name: r'expenseRefundedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// What has come back for one purchase, for Edit expense.

  ExpenseRefundedProvider call(String expenseId) => ExpenseRefundedProvider._(argument: expenseId, from: this);

  @override
  String toString() => r'expenseRefundedProvider';
}

/// Spending from the local day [from] up to [to] (end excluded), for the
/// Money tab: purchases net of their refunds, and the refunds that came back.

@ProviderFor(spending)
final spendingProvider = SpendingFamily._();

/// Spending from the local day [from] up to [to] (end excluded), for the
/// Money tab: purchases net of their refunds, and the refunds that came back.

final class SpendingProvider
    extends $FunctionalProvider<AsyncValue<SpendingReport>, SpendingReport, Stream<SpendingReport>>
    with $FutureModifier<SpendingReport>, $StreamProvider<SpendingReport> {
  /// Spending from the local day [from] up to [to] (end excluded), for the
  /// Money tab: purchases net of their refunds, and the refunds that came back.
  SpendingProvider._({required SpendingFamily super.from, required (DateTime, DateTime) super.argument})
    : super(
        retry: null,
        name: r'spendingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$spendingHash();

  @override
  String toString() {
    return r'spendingProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $StreamProviderElement<SpendingReport> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<SpendingReport> create(Ref ref) {
    final argument = this.argument as (DateTime, DateTime);
    return spending(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is SpendingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$spendingHash() => r'4ee0fa90c2887a1b3cb76bb0c2db7d6399a58b9c';

/// Spending from the local day [from] up to [to] (end excluded), for the
/// Money tab: purchases net of their refunds, and the refunds that came back.

final class SpendingFamily extends $Family
    with $FunctionalFamilyOverride<Stream<SpendingReport>, (DateTime, DateTime)> {
  SpendingFamily._()
    : super(
        retry: null,
        name: r'spendingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Spending from the local day [from] up to [to] (end excluded), for the
  /// Money tab: purchases net of their refunds, and the refunds that came back.

  SpendingProvider call(DateTime from, DateTime to) => SpendingProvider._(argument: (from, to), from: this);

  @override
  String toString() => r'spendingProvider';
}
