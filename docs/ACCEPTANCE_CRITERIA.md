# MVP Acceptance Criteria

## Products

- A category and product can be created with a price stored in cents.
- Categories can be edited, reordered, and deactivated without changing historical order items.
- Deactivating a category hides its products from order entry without changing their flags; reactivation restores products that are still active.
- Products can be edited and deactivated, and active products appear alphabetically within their category.
- Product availability can be toggled without deactivating the product.
- A sold-out product cannot be added to a new order.
- Deactivating or renaming a product does not change previous orders.
- Existing order items preserve their product name, category name, and unit price snapshots after catalog changes.
- Empty, negative, or invalid prices are rejected.

## Tables and orders

- A `DINE_IN` order can be created for a free table.
- A second open order cannot be created for the same table.
- A `TAKEAWAY` order can be created without a table.
- Tables can be created, renamed, reordered, and deactivated when free.
- An occupied table cannot be deactivated and the UI explains the rejection.
- A historical order keeps its table-name snapshot after the table is renamed or deactivated.
- Internal IDs are valid UUIDs, while order numbers are positive sequential business identifiers.
- Allocating an order number and creating its order either both commit or both roll back.
- Adding, removing, and changing quantities updates the total correctly.
- Adding the same product twice produces one line with quantity two at its original price snapshot, and its note applies to that line.
- A persisted sold-out or inactive product line remains visible but cannot be increased.
- Closing and reopening the application preserves open orders.
- Cancelling an open order frees the table and stores reason and timestamp.
- A paid or cancelled order cannot be modified.

## Payments

- Cash requires the received amount to be at least the total.
- An empty order cannot be paid; an order containing a zero-priced product can be paid with a zero total.
- Change equals `received_cents - amount_cents`.
- A transfer requires manual confirmation before persistence.
- Every `PAID` order has exactly one payment, and an `OPEN` or `CANCELLED` order has none.
- The persisted payment amount equals the order total at payment time.
- Payment insertion and order status change either both commit or both roll back.
- Repeated taps do not create duplicate payments.
- After payment, the order is `PAID` and the table is free.

## History and reports

- History displays persisted sales and opens their details.
- History orders sales by `paid_at` descending and shows `paid_at` as the sale date.
- Searching by number returns the correct sale.
- Date and payment-method filters return only matching sales.
- History date filters use `paid_at` rather than order creation time.
- Reports exclude `OPEN` and `CANCELLED` orders.
- Four units of one product count as four units.
- Category reports use each order line's category snapshot.
- Average ticket equals net sales divided by paid orders in the period.
- Net sales equal the sum of payment amounts for paid orders selected by `paid_at`.
- Periods use `America/El_Salvador` while persisted timestamps remain UTC.
- Today, yesterday, this week, this month, and custom ranges produce the expected half-open UTC boundaries.
- The week starts on Monday, and a custom range includes the complete selected end date.
- Sales by hour group `paid_at` by its hour in `America/El_Salvador`.
- Best-selling products, category totals, and payment-method totals match explicit fixture values.

## Backup and restore

- A consistent backup can be exported through Android file storage.
- The backup includes catalog, tables, orders, payments, and settings.
- An incompatible or corrupt backup is rejected without replacing the current database.
- Backup compatibility is checked against the authoritative SQLite `user_version`.
- A preventive backup is created before a valid restore replaces the current database.
- After restore, totals and history match the backup.

## Quality and operation

- The complete product → order → payment → report flow works in airplane mode.
- Every persisted application timestamp uses canonical ISO-8601 UTC text with a `Z` suffix.
- An application update preserves existing data.
- Migrations do not run twice.
- A failed migration rolls back both its schema changes and `user_version` update.
- Data screens cover loading, empty, recoverable-error, success, in-progress, and destructive-confirmation states where applicable.
- Icon-only actions have semantic labels, state is not communicated by color alone, validation errors are associated with their fields, and keyboard focus order is coherent.
- `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test`, and `flutter build apk --debug` pass.
- The APK installs and opens on an Android emulator and the target tablet.
