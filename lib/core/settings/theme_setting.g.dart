// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_setting.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The theme choice read in `bootstrap()` before the first frame, so the app
/// never flashes the wrong theme. Overridden there.

@ProviderFor(initialThemeMode)
final initialThemeModeProvider = InitialThemeModeProvider._();

/// The theme choice read in `bootstrap()` before the first frame, so the app
/// never flashes the wrong theme. Overridden there.

final class InitialThemeModeProvider extends $FunctionalProvider<ThemeMode, ThemeMode, ThemeMode>
    with $Provider<ThemeMode> {
  /// The theme choice read in `bootstrap()` before the first frame, so the app
  /// never flashes the wrong theme. Overridden there.
  InitialThemeModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'initialThemeModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$initialThemeModeHash();

  @$internal
  @override
  $ProviderElement<ThemeMode> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ThemeMode create(Ref ref) {
    return initialThemeMode(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ThemeMode>(value));
  }
}

String _$initialThemeModeHash() => r'85f894fe3cf9d5383256b5481ebb98d3997ca0b1';

/// The current theme choice. Widgets watch it; the theme switches change it.

@ProviderFor(ThemeSetting)
final themeSettingProvider = ThemeSettingProvider._();

/// The current theme choice. Widgets watch it; the theme switches change it.
final class ThemeSettingProvider extends $NotifierProvider<ThemeSetting, ThemeMode> {
  /// The current theme choice. Widgets watch it; the theme switches change it.
  ThemeSettingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeSettingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeSettingHash();

  @$internal
  @override
  ThemeSetting create() => ThemeSetting();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ThemeMode value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ThemeMode>(value));
  }
}

String _$themeSettingHash() => r'bcfadbd0055063b29e8152b84ff117af203c2921';

/// The current theme choice. Widgets watch it; the theme switches change it.

abstract class _$ThemeSetting extends $Notifier<ThemeMode> {
  ThemeMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ThemeMode, ThemeMode>;
    final element =
        ref.element as $ClassProviderElement<AnyNotifier<ThemeMode, ThemeMode>, ThemeMode, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
