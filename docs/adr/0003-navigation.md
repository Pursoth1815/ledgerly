# 0003 Navigation with go_router and a five-tab shell

Status: Accepted (16 Nov 2026)

## Context

Five tabs, each with its own history. Features must not import each other's screens.

## Decision

- `go_router` (18.x) with a `StatefulShellRoute.indexedStack` and one branch, so one navigator, per tab.
- Route paths are constants in `lib/core/routing/route_paths.dart`. `lib/app/router/` maps them to screens. Features navigate by path.
- Tapping the current tab returns to its first page.
- Phase 0A shows placeholder pages; the approved design and the capture button come with Phase 1.

## Alternatives considered

- Navigator 2.0 by hand: more code for the same result.
- One navigator for the whole app: tabs would lose their own history.

## Consequences

- Deep links (notifications, sharing) map onto paths later without new machinery.
