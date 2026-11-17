// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ledger_engine.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The ledger engine, shared by every feature that moves money.

@ProviderFor(ledgerEngine)
final ledgerEngineProvider = LedgerEngineProvider._();

/// The ledger engine, shared by every feature that moves money.

final class LedgerEngineProvider extends $FunctionalProvider<LedgerEngine, LedgerEngine, LedgerEngine>
    with $Provider<LedgerEngine> {
  /// The ledger engine, shared by every feature that moves money.
  LedgerEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ledgerEngineProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ledgerEngineHash();

  @$internal
  @override
  $ProviderElement<LedgerEngine> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  LedgerEngine create(Ref ref) {
    return ledgerEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LedgerEngine value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<LedgerEngine>(value));
  }
}

String _$ledgerEngineHash() => r'60d4f283bddac33ba427656a3fdb6716b0634394';
