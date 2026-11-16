import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_config.g.dart';

/// Which build this is (ADR 0017).
enum Distribution {
  /// The sideloaded build you use every day. SMS detection lives here (Phase 3).
  personal,

  /// The build that could go to a store. It never contains SMS code or permissions.
  store,
}

/// Build-time configuration. The two builds share all business code; they
/// differ only in what this says and in their Android manifests.
@immutable
class AppConfig {
  const AppConfig({required this.distribution});

  /// Reads the Android flavour (Flutter's `appFlavor`). A build without a
  /// flavour (tests, iOS) behaves like the store build, the one with fewer
  /// capabilities.
  factory AppConfig.fromFlavor(String? flavor) => switch (flavor) {
    'personal' => const AppConfig(distribution: Distribution.personal),
    'store' || null => const AppConfig(distribution: Distribution.store),
    _ => throw ArgumentError.value(flavor, 'flavor', 'Unknown build flavour'),
  };

  final Distribution distribution;
}

@Riverpod(keepAlive: true)
AppConfig appConfig(Ref ref) => throw UnimplementedError('appConfigProvider is overridden in bootstrap');
