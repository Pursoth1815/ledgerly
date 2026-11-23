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

/// This calendar month's spending, for the wallet's totals on each card.

@ProviderFor(walletSpending)
final walletSpendingProvider = WalletSpendingFamily._();

/// This calendar month's spending, for the wallet's totals on each card.

final class WalletSpendingProvider
    extends $FunctionalProvider<AsyncValue<SpendingReport>, SpendingReport, Stream<SpendingReport>>
    with $FutureModifier<SpendingReport>, $StreamProvider<SpendingReport> {
  /// This calendar month's spending, for the wallet's totals on each card.
  WalletSpendingProvider._({required WalletSpendingFamily super.from, required DateTime super.argument})
    : super(
        retry: null,
        name: r'walletSpendingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletSpendingHash();

  @override
  String toString() {
    return r'walletSpendingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SpendingReport> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<SpendingReport> create(Ref ref) {
    final argument = this.argument as DateTime;
    return walletSpending(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is WalletSpendingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$walletSpendingHash() => r'6e778615e1f903307f7f79328a259920097840de';

/// This calendar month's spending, for the wallet's totals on each card.

final class WalletSpendingFamily extends $Family with $FunctionalFamilyOverride<Stream<SpendingReport>, DateTime> {
  WalletSpendingFamily._()
    : super(
        retry: null,
        name: r'walletSpendingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// This calendar month's spending, for the wallet's totals on each card.

  WalletSpendingProvider call(DateTime month) => WalletSpendingProvider._(argument: month, from: this);

  @override
  String toString() => r'walletSpendingProvider';
}
