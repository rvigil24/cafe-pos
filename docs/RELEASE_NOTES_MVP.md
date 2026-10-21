# Cafe POS MVP — Release notes

Candidate version: `1.0.0+1`

## Included

- Offline catalog and availability management for categories and products.
- Table management plus dine-in and takeaway orders that persist immediately.
- Cash, manually verified transfer, and manually recorded credit-card payments.
- Read-only sales history and timezone-correct reports for `America/El_Salvador`.
- Business-name setting.
- Consistent SQLite export through Android document storage.
- Validated restore with a preventive local backup and automatic rollback if replacement fails.
- Incremental schema migration through SQLite `user_version`.

## Backup compatibility

- This candidate writes schema version 2.
- Restore accepts Cafe POS schema versions 1 and 2.
- Version 1 is migrated transactionally to version 2 during restore.
- Corrupt files, incomplete schemas, broken foreign keys, and future schema versions are rejected before replacing live data.

## Operational limitations

- One Android device and one local database only.
- Backups are manual; there is no cloud service, synchronization, encryption, or schedule.
- The preventive pre-restore copy remains in app-private storage and is intended for automatic recovery.
- Payments are records only. The app does not contact banks or process cards.
- Printing, fiscal invoicing, split payments, authentication, and the other exclusions in `docs/PRD.md` are not included.

## Installation

Follow `docs/UPGRADE_PROCEDURE.md`. Do not uninstall the existing application
when upgrading because uninstalling removes app-private data.
