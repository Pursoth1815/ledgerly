# Architecture

How the Loopd code is organised and the rules every change follows. The reasons are in [docs/adr](adr/), and the product side is in section 13 of the proposal.

Android is the only implementation target for now. iOS has to keep compiling, and nothing on it is claimed as verified.

## Layers

```text
app/                 start-up, flavour config, router, five-tab shell, More page,
 │                   background entry point (from Phase 0B)
 ▼
features/            one folder per business module; each exposes one public file
 │         ╲
 ▼          ▼
core engines         design_system/   (generic UI only, from Phase 1)
(ledger, capture_inbox, reminders, backup)
 │
 ▼
core infrastructure  (database, security, platform, logging, errors, routing, …)
 │                         │
 ▼                         ▼
packages/ (pure Dart)  Kotlin in android/app (reached only through core/platform)
```

Code depends downward only, and there are no cycles. `app/` is the only place that knows every feature; it wires routes, providers and capture handlers together.

## Folders

`[0A]` exists now. The others are created in the phase that first needs them; empty folders are never created.

| Folder | Holds | Must not hold | Phase |
| --- | --- | --- | --- |
| `lib/main.dart` | The entry point; calls `bootstrap()` | Anything else | [0A] |
| `lib/app/` | Start-up (`bootstrap.dart`), flavour config, router, shell, placeholder pages, the start-up failure screen | Business rules, queries | [0A] |
| `lib/app/background/` | The headless engine's start-up (`backgroundMain()` in `main.dart` calls it) and the list of every background job | Job logic | [0B] |
| `lib/core/database/` | `AppDatabase`, encrypted opening, migrations; later `tables/<owner>.dart` | Queries for one feature (those go in that owner's DAO) | [0A] |
| `lib/core/security/` | Access to Keystore-protected keys; later the crypto calls | Key material stored in Dart | [0A] |
| `lib/core/platform/` | The Pigeon-generated interface; later small services (permissions, notifications, files, usage, share) | Business rules | [0A] |
| `lib/core/logging/` | Logger set-up and redaction | Message text, amounts, digits, names | [0A] |
| `lib/core/errors/` | The sealed `AppException` family | Feature-specific error text | [0A] |
| `lib/core/routing/` | Route path constants | Screens | [0A] |
| `lib/core/background/` | The job runner, the `BackgroundJob` interface and job checkpoints (ADR 0013) | Feature rules | [0B] |
| `lib/core/settings/` | App settings in the `app_settings` table, starting with the theme; later lock timeout and switches | | [1] |
| `lib/core/ledger/` | Accounts, cards, Cash in hand, categories, transactions, postings, money rules | Screens | Phase 2 |
| `lib/core/backup/` | Snapshot, archive, verification, retention, restore | Crypto internals | Phase 2, completed in 7 |
| `lib/core/capture_inbox/` | Drafts, identity hash, transaction sources, merchant memory | Saving final records itself | Phase 3 |
| `lib/core/reminders/` | The schedule worked out from records | Drawing notifications | Phase 5 |
| `lib/core/file_store/` | Encrypted vault and ticket files | | Phase 5 |
| `lib/design_system/` | Tokens (`loopd_colors`, `loopd_typography`, `loopd_spacing`, `loopd_motion`), the theme, and generic components | Domain types, providers, data access | [1] |
| `assets/fonts/` | Bundled Plus Jakarta Sans 2.7.1 and JetBrains Mono 2.304, with their OFL licences | Fonts fetched at run time | [1] |
| `lib/features/<name>/` | One module: `<name>.dart` (public API) plus `domain/`, `data/`, `presentation/` only where needed | Another feature's internals; writes to another owner's tables | From Phase 1 |
| `packages/sms_parser/`, `packages/command_parser/` | Pure Dart parsers with fixture tests | Flutter, the database, app imports | Phases 3 and 9 |
| `pigeons/` | The Pigeon interface definition | | [0A] |
| `tool/` | `check_architecture.dart`, `check_apk_permissions.sh` | App code | [0A] |
| `drift_schemas/` | Committed schema snapshots, one per version | Hand edits | [0A] |
| `android/app/src/main/kotlin/…/` | `bridge/` (Pigeon host code), `security/` (Keystore), `background/` (WorkManager worker, headless engine, single-writer gate); later `alarms/`, `notifications/`, `usage/`, `share/` | Business rules | [0A], `background/` [0B] |
| `android/app/src/profile/` | The Phase 0B spike lab ("Loopd Spikes"), in profile builds only | Anything the release app needs | [0B] |
| `android/app/src/personal/` | Personal-only code and manifest entries (SMS) | | Phase 3 |
| `android/app/src/test/` | Kotlin JVM tests | | [0A] |
| `test/` | Tests mirroring `lib/`, plus `tool/`; later `support/` for shared fakes | Production code | [0A] |
| `integration_test/` | On-device tests | | [0A] |

## Import rules (checked by `dart run tool/check_architecture.dart`)

1. `core` never imports `app`, `features` or `design_system`.
2. `design_system` imports nothing from the app outside itself.
3. A feature never imports `app`. It imports another feature only through that feature's public file `lib/features/<name>/<name>.dart`, and only for reads.
4. A `*_dao.dart` file is imported only inside the folder of the module that owns it. For example, only `core/ledger` may use the ledger DAO.
5. `packages/` never import the app.
6. Kotlin never uses Tink APIs that can store keys unencrypted (`AndroidKeysetManager`, `CleartextKeysetHandle`, unencrypted keyset serialisation, `InsecureSecretKeyAccess`).
7. `pubspec.yaml` has no networking, analytics or font-download packages.

How features talk to each other:

- Writes that cross modules go through core engines.
- Reads go through small read-model providers in a feature's public file.
- Live updates come from Drift's watched queries; there is no event bus.
- Navigation uses the paths in `core/routing`.

## Riverpod

- Riverpod 3 with code generation (`@riverpod`).
- Providers are declared next to the class they provide; the class itself takes its dependencies in its constructor and never sees `ref`.
- Infrastructure is `keepAlive`. The database and the config are opened in `bootstrap()` and injected with `overrideWithValue`.
- Screen state uses auto-dispose providers, with a family for anything looked up by id.
- Live queries are stream providers.
- Business rules live in the domain or in an engine, never in a widget or a notifier.
- Tests use `ProviderScope` or a `ProviderContainer` with overrides.

## Database

- One SQLCipher database, `loopd.db`, in the app's private support folder.
- Its key comes from Kotlin, wrapped by the Android Keystore. A new key is created only when no database file exists.
- The SQLCipher library is the build bundled by the `sqlite3` package (`hooks: user_defines: sqlite3: source: sqlcipher` in `pubspec.yaml`).
- Every connection sets the key first, refuses to continue if `cipher_version` is empty, then sets WAL and a busy timeout. Foreign keys are switched on before the database is used.
- One schema version for the whole file. To change the schema:
  1. Add or change tables in `core/database/tables/<owner>.dart` and raise `schemaVersion`.
  2. Run `dart run drift_dev make-migrations`. It writes the new snapshot to `drift_schemas/` and generates migration tests in `test/drift/`.
  3. Write the step, run the generated tests, and never edit a released step.
- Only one engine writes at a time (ADR 0013). The app's engine takes the writer gate before it opens the database; background jobs run inside it while it exists, and otherwise in the headless engine.

## Native code

- Kotlin lives in the app's own Android project, not in a plugin.
- The interface is defined once in `pigeons/platform_api.dart`. After editing it, run `dart run pigeon --input pigeons/platform_api.dart` and commit the generated files.
- Key work runs on Pigeon's serial background queue, so Keystore calls never overlap.

## Errors and logs

- Raw exceptions are turned into an `AppException` at the data and platform edges.
- Log events carry safe fields only (`open_failed code=database.key_mismatch`). Errors are logged as their type, and every line passes through `redactSensitive`.

## Commands

```sh
flutter pub get
dart run pigeon --input pigeons/platform_api.dart   # after editing pigeons/
dart run build_runner build                         # Drift and Riverpod code
dart run drift_dev make-migrations                  # after a schema change
dart format lib test tool integration_test pigeons
flutter analyze
dart run tool/check_architecture.dart
flutter test --exclude-tags golden                 # what CI runs
flutter test --tags golden                         # visual tests, on the Mac before handing over
flutter test --tags golden --update-goldens        # after an intended visual change; look at the pictures
(cd android && ./gradlew :app:testPersonalDebugUnitTest)
flutter run --flavor personal                       # Android needs a flavour
flutter build apk --release --flavor personal       # or --flavor store
tool/check_apk_permissions.sh build/app/outputs/flutter-apk/app-store-release.apk \
  android.permission.INTERNET android.permission.RECEIVE_SMS android.permission.READ_SMS
flutter test integration_test --flavor personal     # needs a device or emulator
```

Generated files (`*.g.dart`, `PlatformApi.g.kt`) are committed, formatted with `dart format`, and CI fails if regenerating and formatting them changes anything.

## Naming

- Files are snake_case, with role suffixes: `_screen`, `_sheet`, `_notifier`, `_repository`, `_dao`, `_engine`, `_service`.
- Classes use the same roles: `TravelRepository`, `LedgerEngine`, `NotificationService`.
- Drift tables are plural; their row classes are singular.
- Doc comments go on public APIs of engines and packages; comments explain why, not what.
