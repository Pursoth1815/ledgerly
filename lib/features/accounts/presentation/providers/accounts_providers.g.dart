// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accounts_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The bank accounts ([AccountKind.bank]) or cards ([AccountKind.creditCard])
/// that are not removed, oldest first.

@ProviderFor(accountsOfKind)
final accountsOfKindProvider = AccountsOfKindFamily._();

/// The bank accounts ([AccountKind.bank]) or cards ([AccountKind.creditCard])
/// that are not removed, oldest first.

final class AccountsOfKindProvider
    extends $FunctionalProvider<AsyncValue<List<LedgerAccount>>, List<LedgerAccount>, Stream<List<LedgerAccount>>>
    with $FutureModifier<List<LedgerAccount>>, $StreamProvider<List<LedgerAccount>> {
  /// The bank accounts ([AccountKind.bank]) or cards ([AccountKind.creditCard])
  /// that are not removed, oldest first.
  AccountsOfKindProvider._({required AccountsOfKindFamily super.from, required AccountKind super.argument})
    : super(
        retry: null,
        name: r'accountsOfKindProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountsOfKindHash();

  @override
  String toString() {
    return r'accountsOfKindProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<LedgerAccount>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<LedgerAccount>> create(Ref ref) {
    final argument = this.argument as AccountKind;
    return accountsOfKind(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AccountsOfKindProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$accountsOfKindHash() => r'8639773cdf8033b6d7d6fe5391a2a56d0956fa4c';

/// The bank accounts ([AccountKind.bank]) or cards ([AccountKind.creditCard])
/// that are not removed, oldest first.

final class AccountsOfKindFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<LedgerAccount>>, AccountKind> {
  AccountsOfKindFamily._()
    : super(
        retry: null,
        name: r'accountsOfKindProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The bank accounts ([AccountKind.bank]) or cards ([AccountKind.creditCard])
  /// that are not removed, oldest first.

  AccountsOfKindProvider call(AccountKind kind) => AccountsOfKindProvider._(argument: kind, from: this);

  @override
  String toString() => r'accountsOfKindProvider';
}

/// What each account, card and Cash in hand spent in [month]'s calendar
/// month: account id → paise.

@ProviderFor(monthSpending)
final monthSpendingProvider = MonthSpendingFamily._();

/// What each account, card and Cash in hand spent in [month]'s calendar
/// month: account id → paise.

final class MonthSpendingProvider
    extends $FunctionalProvider<AsyncValue<Map<String, int>>, Map<String, int>, Stream<Map<String, int>>>
    with $FutureModifier<Map<String, int>>, $StreamProvider<Map<String, int>> {
  /// What each account, card and Cash in hand spent in [month]'s calendar
  /// month: account id → paise.
  MonthSpendingProvider._({required MonthSpendingFamily super.from, required DateTime super.argument})
    : super(
        retry: null,
        name: r'monthSpendingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthSpendingHash();

  @override
  String toString() {
    return r'monthSpendingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Map<String, int>> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<Map<String, int>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return monthSpending(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthSpendingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthSpendingHash() => r'1d3c72d150a97ac9eae6c530f9bd30e0b315f1db';

/// What each account, card and Cash in hand spent in [month]'s calendar
/// month: account id → paise.

final class MonthSpendingFamily extends $Family with $FunctionalFamilyOverride<Stream<Map<String, int>>, DateTime> {
  MonthSpendingFamily._()
    : super(
        retry: null,
        name: r'monthSpendingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// What each account, card and Cash in hand spent in [month]'s calendar
  /// month: account id → paise.

  MonthSpendingProvider call(DateTime month) => MonthSpendingProvider._(argument: month, from: this);

  @override
  String toString() => r'monthSpendingProvider';
}

/// Cash in hand: the balance, the last count and the last money moved in.

@ProviderFor(cashInHand)
final cashInHandProvider = CashInHandProvider._();

/// Cash in hand: the balance, the last count and the last money moved in.

final class CashInHandProvider extends $FunctionalProvider<AsyncValue<CashInHand>, CashInHand, Stream<CashInHand>>
    with $FutureModifier<CashInHand>, $StreamProvider<CashInHand> {
  /// Cash in hand: the balance, the last count and the last money moved in.
  CashInHandProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cashInHandProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cashInHandHash();

  @$internal
  @override
  $StreamProviderElement<CashInHand> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<CashInHand> create(Ref ref) {
    return cashInHand(ref);
  }
}

String _$cashInHandHash() => r'dec65f17971b993110fbd6c9de550a621116db4e';
