# MVP Acceptance Criteria

## Products

- A category and product can be created with a price stored in cents.
- A sold-out product cannot be added to a new order.
- Deactivating or renaming a product does not change previous orders.
- Empty, negative, or invalid prices are rejected.

## Tables and orders

- A `DINE_IN` order can be created for a free table.
- A second open order cannot be created for the same table.
- A `TAKEAWAY` order can be created without a table.
- Adding, removing, and changing quantities updates the total correctly.
- Closing and reopening the application preserves open orders.
- Cancelling an open order frees the table and stores reason and timestamp.
- A paid or cancelled order cannot be modified.

## Payments

- Cash requires the received amount to be at least the total.
- Change equals `received_cents - amount_cents`.
- A transfer requires manual confirmation before persistence.
- Payment insertion and order status change either both commit or both roll back.
- Repeated taps do not create duplicate payments.
- After payment, the order is `PAID` and the table is free.

## History and reports

- History displays persisted sales and opens their details.
- Searching by number returns the correct sale.
- Reports exclude `OPEN` and `CANCELLED` orders.
- Four units of one product count as four units.
- Category reports use each order line's category snapshot.
- Average ticket equals net sales divided by paid orders in the period.
- Periods use `America/El_Salvador` while persisted timestamps remain UTC.

## Backup and restore

- A consistent backup can be exported through Android file storage.
- The backup includes catalog, tables, orders, payments, and settings.
- An incompatible or corrupt backup is rejected without replacing the current database.
- A preventive backup is created before a valid restore replaces the current database.
- After restore, totals and history match the backup.

## Quality and operation

- The complete product → order → payment → report flow works in airplane mode.
- An application update preserves existing data.
- Migrations do not run twice.
- `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test`, and `flutter build apk --debug` pass.
- The APK installs and opens on an Android emulator and the target tablet.
