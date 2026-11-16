# 0015 Naming, formatting and lints

Status: Accepted (16 Nov 2026)

## Context

One developer, a long project: consistency must come from tools.

## Decision

- `flutter_lints` plus strict analyzer modes (strict casts, inference and raw types) and extra rules (unawaited futures, final locals, single quotes, directive order and others), in `analysis_options.yaml`.
- `dart format` is checked in CI. Generated files are excluded from analysis.
- Naming: snake_case files with role suffixes; Drift tables plural; doc comments on public APIs of engines and packages.

## Alternatives considered

- `very_good_analysis`: stricter than needed for this project.

## Consequences

- `flutter analyze` must be clean before any change is handed over.
