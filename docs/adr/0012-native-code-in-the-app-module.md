# 0012 Native code in the app module, with Pigeon

Status: Accepted (16 Nov 2026)

## Context

SMS, notifications, alarms, usage access, sharing, widgets and the bubble are native. The store build must contain no SMS code or permissions.

## Decision

- Kotlin lives in `android/app` (no plugin), organised by package: `bridge/`, `security/`, and later `background/`, `alarms/`, `notifications/`, `usage/`, `share/`.
- One Pigeon interface, `pigeons/platform_api.dart`, generates Dart and Kotlin. Only `lib/core/platform/` talks to it.
- Personal-only code and manifest entries go in `android/app/src/personal/`; the store flavour gets stubs.
- Kotlin is tested with JVM unit tests in `android/app/src/test/`.

## Alternatives considered

- A local Flutter plugin: its manifest would merge into both flavours, and it fits the app's lifecycle and headless engine awkwardly.

## Consequences

- Per-flavour permissions come for free. There is one Android project to maintain.
