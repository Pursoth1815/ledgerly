# 0017 Build flavours and permission checks

Status: Accepted (16 Nov 2026)

## Context

A sideloaded personal build has SMS detection; a store build must never carry SMS code or permissions. The app must have no internet permission.

## Decision

- Android product flavours `personal` and `store`, in the `distribution` dimension. Android builds always name the flavour (`flutter run --flavor personal`). A default flavour in `pubspec.yaml` is not used, because Flutter applies it to iOS too, and iOS has no flavours, so its build would fail.
- Both use the application id `com.pursoth.loopd`. A separate store id is pending.
- minSdk 35; target and compile SDK follow Flutter's current defaults.
- Dart reads the flavour into `AppConfig`. A build with no flavour behaves like store, and an unknown flavour is an error.
- `tool/check_apk_permissions.sh` fails CI if a release APK requests the internet, or if the store APK requests SMS. Debug builds keep the internet permission that Flutter needs for hot reload.
- Release builds use debug signing until Phase 11.

## Alternatives considered

- Separate Dart entry points per flavour: duplicated start-up code.

## Consequences

- The two builds share all business code.
