// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'today_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Spending in [month]'s calendar month so far, for the Spending card. Today's
/// own total is the part of it dated today.

@ProviderFor(todayMonthSpending)
final todayMonthSpendingProvider = TodayMonthSpendingFamily._();

/// Spending in [month]'s calendar month so far, for the Spending card. Today's
/// own total is the part of it dated today.

final class TodayMonthSpendingProvider
    extends $FunctionalProvider<AsyncValue<SpendingReport>, SpendingReport, Stream<SpendingReport>>
    with $FutureModifier<SpendingReport>, $StreamProvider<SpendingReport> {
  /// Spending in [month]'s calendar month so far, for the Spending card. Today's
  /// own total is the part of it dated today.
  TodayMonthSpendingProvider._({required TodayMonthSpendingFamily super.from, required DateTime super.argument})
    : super(
        retry: null,
        name: r'todayMonthSpendingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayMonthSpendingHash();

  @override
  String toString() {
    return r'todayMonthSpendingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<SpendingReport> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<SpendingReport> create(Ref ref) {
    final argument = this.argument as DateTime;
    return todayMonthSpending(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TodayMonthSpendingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$todayMonthSpendingHash() => r'00e98612ffc2d234545f85eabc5ebef4976f5ead';

/// Spending in [month]'s calendar month so far, for the Spending card. Today's
/// own total is the part of it dated today.

final class TodayMonthSpendingFamily extends $Family with $FunctionalFamilyOverride<Stream<SpendingReport>, DateTime> {
  TodayMonthSpendingFamily._()
    : super(
        retry: null,
        name: r'todayMonthSpendingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Spending in [month]'s calendar month so far, for the Spending card. Today's
  /// own total is the part of it dated today.

  TodayMonthSpendingProvider call(DateTime month) => TodayMonthSpendingProvider._(argument: month, from: this);

  @override
  String toString() => r'todayMonthSpendingProvider';
}

/// Where backup stands, for the Backup card.

@ProviderFor(todayBackupStatus)
final todayBackupStatusProvider = TodayBackupStatusProvider._();

/// Where backup stands, for the Backup card.

final class TodayBackupStatusProvider
    extends $FunctionalProvider<AsyncValue<BackupStatus>, BackupStatus, Stream<BackupStatus>>
    with $FutureModifier<BackupStatus>, $StreamProvider<BackupStatus> {
  /// Where backup stands, for the Backup card.
  TodayBackupStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayBackupStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayBackupStatusHash();

  @$internal
  @override
  $StreamProviderElement<BackupStatus> $createElement($ProviderPointer pointer) => $StreamProviderElement(pointer);

  @override
  Stream<BackupStatus> create(Ref ref) {
    return todayBackupStatus(ref);
  }
}

String _$todayBackupStatusHash() => r'8df3c5cdcb58e8edf040c82810ec35d4a17bf4cc';
