# Android release operation

Distribute a signed universal APK through
[GitHub Releases](https://github.com/rvigil24/cafe-pos/releases).
Trial versions are marked **Pre-release**.

## Signing identity

Keep application ID `com.rvigil.cafe_pos` and the same release signing key for
future updates. Never commit signing material or attach it to a release.

On the owner's machine, the RSA 4096/JKS release key and credentials are in
`~/.local/share/cafe-pos/signing/`. A private recovery archive is at
`~/Documents/CafePOS-private/signing-backup-2026-10-21.tar`.
Copy this archive to secure owner-controlled external storage: a second local
file does not protect against machine loss. It contains passwords and must be
protected like the keystore. The key has a 10,000-day validity period.

Configure an ignored `android/key.properties`:

```properties
storeFile=/absolute/private/path/cafe-pos-release.jks
storePassword=<private store password>
keyAlias=cafe-pos
keyPassword=<private key password>
```

Use restrictive permissions (`chmod 600`) for credentials and keystores.
Debug builds work without this file. Release builds fail for missing properties
or keystores; bad passwords/aliases are rejected by Android signing validation.
Release signing never falls back to debug. Restore the original key when moving
to a new machine; do not generate a new identity for each release.

## Build and verify

1. Start from a reviewed release branch and increase the `pubspec.yaml` build
   number for every distributed APK. `1.0.0-beta.1+2` maps to version name
   `1.0.0-beta.1` and version code `2`.
2. Run `./cafe check`, the existing integration suite on a physical Android
   device, and `flutter build apk --debug`. Never start an emulator here.
3. Run `flutter build apk --release` with the default `lib/main.dart` entry point.
   Do not distribute a development-seed or integration-test APK.
4. Use SDK Build Tools `apksigner verify --verbose --print-certs` and
   `aapt dump badging` on `build/app/outputs/flutter-apk/app-release.apk`.
   Confirm the certificate, package, version, API 24 minimum, supported ABIs,
   and absence of `application-debuggable`. Set `JAVA_HOME` to Flutter's
   configured JDK if required by `apksigner`.
5. Install and launch the exact APK on a physical Android device. Verify the
   sales flow, restart persistence, Android file export/restore, and same-key
   in-place update preservation. Record commands, device, outcomes, certificate
   fingerprint, APK checksum, source revision, and any remaining limitations.

## Publish

Commit the reviewed changes before tagging. Publish `v1.0.0-beta.1` as a
prerelease from that exact verified commit. Push the release branch and tag.
Attach only `cafe-pos-1.0.0-beta.1.apk`, `SHA256SUMS`, and `INSTRUCCIONES.md`
(copied from `docs/INSTALACION_PRUEBAS.md`). Generate SHA-256 after naming the
APK. Use `docs/RELEASE_NOTES_MVP.md` for release notes.

Use `gh release create` with `--verify-tag`, `--prerelease`,
`--notes-file docs/RELEASE_NOTES_MVP.md`, and the artifact paths. Verify the
downloaded asset checksum against the local APK. Never include device snapshots,
real data, credentials, or keystores.

Subsequent updates retain the key and package ID with increasing build numbers.
Users manually download and install updates over the existing application.
Follow `docs/UPGRADE_PROCEDURE.md` and retain a verified external database backup.
