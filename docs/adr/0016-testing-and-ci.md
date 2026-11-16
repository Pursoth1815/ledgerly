# 0016 Testing strategy and CI

Status: Accepted (16 Nov 2026)

## Context

Money, data integrity, security and the main journeys must be provably right, without chasing a coverage number.

## Decision

- Tests:
  - unit tests for rules and invariants
  - database tests on real SQLCipher files
  - generated migration tests
  - parser fixtures
  - widget and golden tests (goldens on Linux only)
  - Kotlin JVM tests
  - backup round trips and integration tests on a device before releases
- `test/` mirrors `lib/`; shared fakes go in `test/support/` once there is more than one user.
- GitHub Actions (`.github/workflows/ci.yml`):
  - checks job: generated code current, format, analyse, architecture check, Dart tests
  - Android job: Kotlin tests, both release builds, permission check
  - iOS compile check: by hand only, until its frequency is decided

## Alternatives considered

- An emulator on every push: slow and expensive.

## Consequences

- Pending: how often the iOS compile check runs.
