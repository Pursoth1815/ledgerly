# 0002 Riverpod 3 with code generation

Status: Accepted (16 Nov 2026)

## Context

The database emits live query results, screens need dependency injection, and tests need easy overrides. Business logic must not drift into widgets or providers.

## Decision

- Riverpod 3 (`flutter_riverpod` 3.5) with `riverpod_generator`. `build_runner` is already needed for Drift.
- Providers are declared next to what they provide. Classes take their dependencies in the constructor and never see `ref`. Domain code has no Riverpod at all.
- Infrastructure providers are `keepAlive`. The database and the config are opened in `bootstrap()` and injected with `overrideWithValue`.
- Kinds of provider:
  - stream providers for live queries
  - `AsyncNotifier` for a screen with loading and actions
  - `Notifier` for form state
  - plain providers for services, repositories and engines
  - families for "by id" screens
- No interface-plus-implementation pairs for repositories: Dart classes can be faked with `implements` or `extends`. A use case exists only for a flow that spans several owners.
- A notifier orchestrates; it holds no rules. Derived values are separate providers. Global state only for settings, theme and lock state.

## Alternatives considered

- BLoC: equally sound, with more boilerplate for this app.
- Riverpod without code generation: fewer generated files, but less consistent naming and auto-dispose behaviour.

## Consequences

- One way to wire everything, and tests override any dependency.
- Generated `*.g.dart` files are committed, and CI checks they are current.
