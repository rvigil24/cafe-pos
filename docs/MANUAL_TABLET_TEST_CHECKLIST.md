# Cafe POS — Manual tablet test checklist

Use a physical Android tablet or phone in landscape orientation. Never run an
Android emulator on the development machine. Record the device, Android
version, APK hash, date, expected result, actual result, and cleanup in the
active milestone evidence file.

## Preparation

- [ ] Confirm the worktree is clean and the candidate APK was built from the recorded commit.
- [ ] Record `sha256sum build/app/outputs/flutter-apk/app-debug.apk`.
- [ ] Connect the physical device and confirm `flutter devices` reports `emulator: false`.
- [ ] Keep a known-good exported backup outside the app before destructive checks.
- [ ] Use only fictitious data in screenshots, logs, and committed artifacts.

## Backup and restore

- [ ] In Configuración, change the business name and confirm it survives leaving and reopening the section.
- [ ] Create at least one category, product, table, paid order, and reportable payment.
- [ ] Select **Exportar respaldo**, choose a location in Android Files, and confirm success.
- [ ] Verify the exported `.db` file remains available outside the app.
- [ ] Change the catalog or business name after export so restored state is distinguishable.
- [ ] Select **Restaurar respaldo**, read the warning, cancel once, and confirm nothing changes.
- [ ] Restore a corrupt or incompatible `.db`; confirm an explanatory error and unchanged live data.
- [ ] Restore the valid export and confirm catalog, tables, orders, payments, settings, history, and report totals match it.
- [ ] Confirm the app remains usable immediately after restore without being reinstalled.

## Offline, restart, and update

- [ ] With USB debugging available, enable airplane mode; do not use Wi-Fi debugging for this check.
- [ ] Complete product → order → payment → history → report while offline.
- [ ] Leave an order open, force-stop Cafe POS, reopen it, and confirm the order is preserved.
- [ ] Reboot the device, reopen Cafe POS, and confirm the same persisted state.
- [ ] Install the candidate APK over the previous APK without uninstalling or clearing app data.
- [ ] Confirm existing data and the next sequential order number survive the update.
- [ ] Confirm a previously migrated database does not run a migration twice.
- [ ] Disable airplane mode during cleanup and leave the production-entry APK installed.

## Touch, errors, and accessibility

- [ ] Check both landscape orientations and the shortest supported viewport.
- [ ] Confirm primary controls are comfortably touchable and at least 48 × 48 dp.
- [ ] Confirm icon-only buttons expose meaningful accessibility labels/tooltips.
- [ ] Confirm free/occupied, active/inactive, loading, and error states are not distinguished by color alone.
- [ ] Confirm validation errors identify their fields and focus remains visible with an external keyboard.
- [ ] Confirm loading, empty, success, in-progress, recoverable-error, and destructive-confirmation states affected by the milestone.
- [ ] Repeatedly tap payment, export, and restore actions; confirm no duplicate payment or concurrent maintenance operation occurs.

## Final cleanup

- [ ] Rebuild the normal production-entry debug APK after integration tests.
- [ ] Install and open that APK with `flutter run --no-build --no-resident`.
- [ ] Confirm no test runner remains installed or open.
- [ ] Preserve the external known-good backup; remove only disposable fictitious test files.
