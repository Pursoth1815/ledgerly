# 0014 Errors and logging with redaction

Status: Accepted (16 Nov 2026)

## Context

Logs must help find problems without ever holding money, account digits, names or message text.

## Decision

- A sealed `AppException` family in `lib/core/errors/`. Phase 0A has `KeyAccessException` and `DatabaseOpenException`; others are added when needed.
- Raw exceptions are converted at the data and platform edges, and screens map exceptions to words in one place.
- A result type is used only for expected outcomes, such as parser results and form validation.
- `package:logging` with events that carry safe fields only. Errors are logged as their type. Every line passes `redactSensitive` (amounts, runs of four or more digits, UPI ids). Lines go to the debug console in debug builds; the on-phone file and Export logs come later.

## Alternatives considered

- Result types everywhere: boilerplate across every call.
- Free-text logging: leaks data.

## Consequences

- Redaction is a safety net, not permission to log data.
