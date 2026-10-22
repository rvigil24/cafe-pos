# First GitHub prerelease

Date: 2026-10-21 (America/El_Salvador).
State: approved by the owner on 2026-10-21 ("lo apruebo"); implementation,
verification, and GitHub prerelease publication completed on 2026-10-21. See
`docs/RELEASE_EVIDENCE_1.0.0-beta.1.md`.

## Objective and scope

Publish a signed, universal Android APK for business trials through
`rvigil24/cafe-pos` GitHub Releases. The owner selected GitHub Releases.
Proposed version: `1.0.0-beta.1+2`; tag: `v1.0.0-beta.1`, marked prerelease.
Keep application ID `com.rvigil.cafe_pos` and Android API 24 minimum.

This is release preparation outside the completed implementation milestones.
There are no product features, dependency updates, architecture changes, schema
changes, new migrations, or changes to transaction boundaries or business rules.
No Play Store submission, automatic updater, hosting service, or CI is included.

## Baseline

- Initial branch: `main`, clean worktree; milestone 6 records owner acceptance.
- Planning branch: `docs/release-preparation`.
- GitHub repository: public; no existing releases were returned by `gh release list`.
- Current application version: `1.0.0+1`.
- Release builds currently use the debug signing configuration.
- `android/key.properties` does not exist; no release key has been selected.
- Physical device detected: Infinix X6873, Android 16/API 36, arm64.
- `./scripts/check.sh`: passed dependency resolution, formatting (105 files,
  no changes), analysis (no issues), and all 72 unit/widget tests.
- At intake, APK builds, integration tests, and signed-release runtime checks
  were pending; final outcomes are recorded in the release evidence.

## Implementation order

1. Work on a separate `fix/android-release` branch. Generate a dedicated local
   release keystore unless the owner supplies an existing release identity.
   Store it and its random credentials outside tracked source; retain restrictive
   file permissions. Document their local locations without recording secrets.
   Arrange an owner-controlled backup before publication; never attach signing
   material to GitHub Releases or commit it.
2. Configure Gradle to use `android/key.properties` for release signing and fail
   clearly when release signing is unavailable. Debug builds must remain usable
   without that file. Verify all credential and keystore paths are ignored.
3. Set `pubspec.yaml` to `1.0.0-beta.1+2`. Build the normal production entry point
   into one universal release APK, without development seed data.
4. Verify the APK signature, application ID, version name/code, API floor, and
   absence of the debuggable flag. Record certificate fingerprint and APK SHA-256.
5. Run applicable automated checks and Android integration tests on the connected
   physical device. Verify the signed release launches and supports catalog,
   order, payment, history/report, restart, export, and restore flows. Prove an
   in-place same-key APK update preserves representative data. Do not start an
   emulator or silently uninstall/reset the owner's application.
6. Update `README.md`, `docs/RELEASE_NOTES_MVP.md`, and
   `docs/UPGRADE_PROCEDURE.md`; add concise release evidence and Spanish tester
   instructions covering download, Android installation permission, local-only
   storage, manual backups, and installing subsequent updates.
7. Review the diff and relevant acceptance criteria, commit coherent changes,
   and prepare release notes plus `cafe-pos-1.0.0-beta.1.apk` and
   `SHA256SUMS`. Publish the prerelease from the exact verified commit, push
   the release branch/tag, and provide its download URL. Follow repository owner
   acceptance rules before integrating the branch into `main`.

## Verification and evidence

Use the existing scripts for device selection and memory-limited Android builds.
Run `flutter pub get`, `dart format --output=none --set-exit-if-changed .`,
`flutter analyze`, `flutter test`, `flutter build apk --debug`, and
`flutter build apk --release`. Run the existing integration suite on the physical
Android target using the repository's prebuilt-APK workflow. Record exact
commands, device, outcomes, artifact checksum, signing certificate fingerprint,
source commit, manual steps, and any limitations in the release evidence.

Apply `docs/ACCEPTANCE_CRITERIA.md` to installation, persistence after restart,
APK update preservation, migration, backup/restore, and the critical sales flow.
No new business behavior needs new unit tests. Verify release packaging directly.
If a required check fails or device verification is unavailable, keep the
release unpublished and report the concrete blocker.

## Risks and recovery

- Debug-signed development installs cannot be updated directly by an APK signed
  with a different release key. Export and verify a backup before any explicitly
  approved replacement, then restore and compare data. Never silently delete
  the development install or its data.
- Future production updates must retain the package ID and signing identity,
  with increasing build numbers. Losing the signing key prevents ordinary
  updates; keep an independent secure backup of the key and credentials.
- The repository and download are public. Anyone with the URL can obtain the
  APK; the app has no authentication. No real business data belongs in artifacts.
- Before publication, rollback means discarding the candidate and fixing its
  branch. After publication, preserve the release identity and issue a corrected
  higher-build APK; do not rely on Android downgrades. Keep verified external
  database backups and use the documented compatible restore procedure.

## Reference

- [Flutter Android release guide](https://docs.flutter.dev/deployment/android)
- [Android app signing](https://developer.android.com/studio/publish/app-signing)
