# 0001 Layers, feature-first folders and import rules

Status: Accepted (16 Nov 2026)

## Context

Nine modules are built by one person over thirteen phases. The tabs (Today, Money, Travel, Planner, More) group modules for navigation, but they are not the business modules themselves. Rules that nobody checks erode within weeks.

## Decision

- Feature-first folders under `lib/features/`: today, expenses, lending, travel, notes, tasks, document_vault, digital_wellbeing, capture, settings. The tabs and the More page live in `lib/app/`.
- Each feature has `domain/`, `data/` and `presentation/` only where it has content for them. Today, capture and settings are mostly presentation.
- Each feature exposes one public file, `<name>.dart`. Other code imports only that file, and only for reads.
- Shared rules live in four engines in `lib/core/`: ledger, capture_inbox, reminders and backup. Infrastructure (database, security, platform, logging, errors, routing) lives beside them. There is no `services/` or `utils/` folder.
- Dependencies point down: app → features → core → packages. The design system depends on nothing in the app.
- `tool/check_architecture.dart` enforces this in CI.

## Alternatives considered

- Folders per tab (money, planner, more): they mix modules that change for different reasons.
- Full Clean Architecture in every feature: it roughly doubles the files for small modules.
- One package per feature (melos, workspaces): heavy for one app and one developer.

## Consequences

- Each module can be built and tested in its own phase.
- Boundaries hold because they are checked, not because of folder ceremony.
- Cross-module work needs an engine or a read model, which is a little more design up front.
