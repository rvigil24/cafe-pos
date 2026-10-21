# Cafe POS — Upgrade and recovery procedure

## Before an upgrade

1. Open the currently installed Cafe POS.
2. Go to **Configuración → Negocio y respaldos**.
3. Select **Exportar respaldo** and save the `.db` file to a location outside the application.
4. Confirm Android Files shows the exported file and keep it until the upgraded app is verified.
5. Record the current business name, latest order number, and one recent sale total for comparison.

## Install the candidate

1. Verify the APK SHA-256 against the value recorded in the milestone evidence.
2. Install the APK over the existing `com.rvigil.cafe_pos` application.
3. Do **not** uninstall the existing app and do not clear its storage.
4. Open Cafe POS. Startup runs each pending migration once and preserves existing rows.
5. Confirm the business name, catalog, open orders, latest sale, and reports.
6. Create and reopen a small fictitious order, then remove or cancel it as appropriate.

For development-device installation:

```bash
flutter run -d <physical-device-id> --no-build --no-resident \
  --use-application-binary=build/app/outputs/flutter-apk/app-debug.apk
```

## Restore after device or data loss

1. Install the same or a newer compatible Cafe POS version.
2. Open **Configuración → Negocio y respaldos**.
3. Select **Restaurar respaldo** and review the replacement warning.
4. Choose the external `.db` file.
5. Wait for the success message; do not close the app during replacement.
6. Verify the business name, catalog, tables, sales history, and report totals.

Cafe POS validates the selected file before replacement. It also creates a
validated preventive copy of the current database in app-private storage. If
replacement, migration, or final validation fails, the app restores the prior
database automatically and reports a recoverable error.

## If validation rejects a file

- Keep the application open and confirm current data is unchanged.
- Do not rename arbitrary files to `.db` or edit a backup manually.
- Try another known-good Cafe POS export.
- Record the exact error, application version, file source, and device details.
- Preserve both the rejected file and the last known-good export for diagnosis.
