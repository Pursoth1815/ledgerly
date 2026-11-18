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
