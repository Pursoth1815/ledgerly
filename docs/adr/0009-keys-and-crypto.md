# 0009 Keys and cryptography

Status: Accepted; verification pending in Phase 0B (16 Nov 2026)

## Context

Financial data and documents must be encrypted at rest. Background work runs while the phone is locked. Tink 1.24.0's `AndroidKeysetManager` stores keysets unencrypted when the Keystore misbehaves, and tries to read them as unencrypted when decryption fails.

## Decision

- **Master key:** AES-256-GCM in the Android Keystore, created through Tink's `AndroidKeystore` helper with its default spec: no user authentication and no unlocked-device requirement.
- **Database key:** 32 random bytes, wrapped by the master key, stored as `[format byte 1][ciphertext]` in `noBackupFilesDir/keys/database.key` (built in Phase 0A).
  - Written atomically, after a successful round trip.
  - Failures report `key_missing`, `key_corrupt` or `keystore_unavailable`, and never create a replacement key.
- **Keysets** (vault, backup) are saved only with encrypted serialisation under the master key.
- **Forbidden APIs:** `AndroidKeysetManager`, `CleartextKeysetHandle`, unencrypted keyset serialisation, `InsecureSecretKeyAccess` (outside one reviewed file, once needed), `doNotUseKeystore`. Checked in CI.
- **Files and backups:** Tink streaming `AES256_GCM_HKDF_1MB`, with associated data binding each file to its identity. **Passphrase:** Argon2id via Bouncy Castle.
- **Pinned** after checking Maven Central on 16 Nov 2026: `tink-android` 1.24.0 (added now) and `bcprov-jdk18on` 1.86 (added with backup). Rule: use the newest release that is at least two weeks old.
- Keystore calls run one at a time on one background thread.
- App lock and the vault prompt control access; they are not the encryption.
- **Phase 0B pass marks on the owner's phone:**
  - 1,000 Keystore cycles and a restart with no failures
  - a 20 MB decrypt in under 1 s and a 10 MB encrypt in under 1 s
  - 200 MB without a memory failure and under 10 MB of extra memory
  - Argon2id between 0.5 and 1.5 s

## Alternatives considered

- `AndroidKeysetManager`: rejected for its unencrypted fallback.
- Plain `javax.crypto` with a Keystore key: equivalent. Kept as the fallback behind `KeyWrapper`.
- libsodium, `age`, pure-Dart crypto: considered; weaker maintenance on mobile or slow on large files.

## Consequences

- The design counts as verified only after the Phase 0B results are recorded here.
- If the Keystore proves unreliable, the owner chooses between refusing to run and a passphrase at app start.
- iOS needs its own crypto work. Tink's iOS library has no streaming encryption, so Tink C++ is tried first, and a Swift implementation with shared test vectors only if that fails.
