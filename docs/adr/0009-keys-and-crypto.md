# 0009 Keys and cryptography

Status: Accepted (16 Nov 2026). Encryption benchmarks and the Keystore stress test verified on the owner's phone (17 Nov 2026); the Keystore-while-locked test is still pending in Phase 0B.

## Context

Financial data and documents must be encrypted at rest. Background work runs while the phone is locked. Tink 1.24.0's `AndroidKeysetManager` stores keysets unencrypted when the Keystore misbehaves, and tries to read them as unencrypted when decryption fails.

## Decision

- **Master key:** AES-256-GCM in the Android Keystore, created through Tink's `AndroidKeystore` helper with its default spec: no user authentication and no unlocked-device requirement.
- **Database key:** 32 random bytes, wrapped by the master key, stored as `[format byte 1][ciphertext]` in `noBackupFilesDir/keys/database.key` (built in Phase 0A).
  - Written atomically, after a successful round trip.
  - Failures report `key_missing`, `key_corrupt` or `keystore_unavailable`, and never create a replacement key.
- **Keysets** (vault, backup) are saved only with encrypted serialisation under the master key.
- **Forbidden APIs:** `AndroidKeysetManager`, `CleartextKeysetHandle`, unencrypted keyset serialisation, `InsecureSecretKeyAccess` (outside one reviewed file, once needed), `doNotUseKeystore`. Checked in CI.
- **Files and backups:** Tink streaming AES-GCM-HKDF with AES-256 keys, HKDF-SHA256 and **256 KiB ciphertext segments** (chosen by the owner from the Phase 0B results, 17 Nov 2026; this replaces `AES256_GCM_HKDF_1MB`), with associated data binding each file to its identity.
- **Passphrase:** Argon2id via Bouncy Castle, **m = 128 MiB, t = 4, p = 1**, 32-byte output (chosen 17 Nov 2026 from the Phase 0B tuning). The settings are stored in each backup's header, so they can be raised later without breaking older backups.
- **Pinned** after checking Maven Central on 16 Nov 2026: `tink-android` 1.24.0 (added now) and `bcprov-jdk18on` 1.86 (added with backup). Rule: use the newest release that is at least two weeks old.
- Keystore calls run one at a time on one background thread.
- App lock and the vault prompt control access; they are not the encryption.
- **Phase 0B pass marks on the owner's phone:**
  - 1,000 Keystore cycles and a restart with no failures
  - a 20 MB decrypt in under 1 s and a 10 MB encrypt in under 1 s
  - 200 MB without a memory failure and under 10 MB of extra memory
  - Argon2id between 0.5 and 1.5 s

## Phase 0B results (17 Nov 2026)

Owner's phone: Tecno Pova Curve 5G (TECNO LJ8k), Android 16 (API 36), HiOS build LJ8k-16.3.0.160SP03. Profile build with `debuggable=false`; max app memory 256 MB. Measured with the spike lab (`android/app/src/profile/`, profile builds only).

- **Keystore stress:** PASS.
  - 1,000 wrap-and-unwrap cycles with 0 failures.
  - A value wrapped in boot 60 unwrapped in boot 61, after a restart.
  - Per cycle: median 51.5 ms just after install, and 17.7 ms after the restart (p95 35.9 ms, max 67.1 ms).
- **Tink streaming:** PASS with 256 KiB segments.
  - Live memory is measured by collecting garbage before each sample. Peaks that include uncollected garbage (about 15–28 MB) depend on when the garbage collector runs, so they are reported but not judged.
  - Every decrypted file matched its original.

  | Segment | 10 MB encrypt | 20 MB decrypt | 200 MB encrypt / decrypt | 200 MB live memory (encrypt / decrypt) |
  | --- | --- | --- | --- | --- |
  | 1 MB | 49 ms | 73 ms | 833 / 639 ms | 9.1 / 9.3 MB (10.2 MB in an earlier run: borderline) |
  | **256 KiB (chosen)** | **44 ms** | **72 ms** | **681 / 714 ms** | **2.4 / 4.8 MB** |
  | 64 KiB | 268 ms | 84 ms | 5,514 / 735 ms | 2.0 / 3.2 MB |
  | 4 KiB | 229 ms | 130 ms | 5,366 / 1,988 ms | 1.0 / 2.1 MB |

- **Argon2id:** PASS.
  - Bouncy Castle matches the RFC 9106 Argon2id test vector.
  - Slowest of two runs at p = 1: 128 MiB takes 497 ms at t = 1, 711 ms at t = 2, 908 ms at t = 3 and 1,102 ms at t = 4.
  - 64 MiB at t = 4 takes 481 ms, just under the window. RFC 9106's 64 MiB, t = 3, p = 4 takes 370 ms, because Bouncy Castle runs the lanes one after another.
  - Chosen: 128 MiB, t = 4 (1.1 s).

## Alternatives considered

- `AndroidKeysetManager`: rejected for its unencrypted fallback.
- Plain `javax.crypto` with a Keystore key: equivalent. Kept as the fallback behind `KeyWrapper`.
- libsodium, `age`, pure-Dart crypto: considered; weaker maintenance on mobile or slow on large files.

## Consequences

- The design counts as verified only after the Phase 0B results are recorded here. The benchmark and stress results are recorded above; the Keystore-while-locked test is still to come.
- Argon2id at 128 MiB uses half of the app's 256 MB Java heap while it runs, so it must run while nothing else large is in memory. This is checked when backup is built (Phase 7).
- If the Keystore proves unreliable, the owner chooses between refusing to run and a passphrase at app start.
- iOS needs its own crypto work. Tink's iOS library has no streaming encryption, so Tink C++ is tried first, and a Swift implementation with shared test vectors only if that fails.
