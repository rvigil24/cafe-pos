# MVP Architecture

## 1. Decision

The application is a Flutter Android app with local SQLite. Flutter renders the tablet interface, plain Dart application code coordinates business operations, and infrastructure code owns SQLite and Android-specific details.

```text
Flutter widgets and screens
            ↓
Application use cases/controllers
            ↓
Domain entities and repository contracts
            ↓
SQLite repository implementations
            ↓
SQLite adapter/plugin
            ↓
Local SQLite database
```

Widgets must never execute SQL. Domain and application code must not import Flutter UI or SQLite packages.

## 2. Target structure

```text
lib/
  main.dart
  app/
    app.dart
    routes.dart
    theme.dart
  application/
    use_cases/
      create_order.dart
      add_item_to_order.dart
      pay_order.dart
      cancel_order.dart
    services/
      transaction_runner.dart
  domain/
    entities/
      category.dart
      product.dart
      order.dart
      order_item.dart
      payment.dart
      cafe_table.dart
    repositories/
      category_repository.dart
      product_repository.dart
      table_repository.dart
      order_repository.dart
      payment_repository.dart
      settings_repository.dart
      sales_repository.dart
      report_repository.dart
    errors/
  features/
    products/
      pages/
      widgets/
      controllers/
    tables/
    orders/
    payments/
    sales/
    reports/
    settings/
  infrastructure/
    backup/
    database/
      migrations/
      sqlite/
    repositories/
      sqlite_category_repository.dart
      sqlite_product_repository.dart
      sqlite_table_repository.dart
      sqlite_order_repository.dart
      sqlite_payment_repository.dart
      sqlite_settings_repository.dart
      sqlite_sales_repository.dart
      sqlite_report_repository.dart
  shared/
    widgets/
    money/
    dates/
    validation/

test/
integration_test/
```

## 3. Responsibilities

### `main.dart`

The application entry point. It initializes Flutter and starts the root app.

### `app/`

Global composition: routes, theme, dependency wiring, and application-level configuration.

### `features/`

User-facing vertical slices. A feature contains Flutter pages, widgets, controllers, and presentation-specific state. For example, `features/payments/` contains the payment screen and cash form, but not SQL.

### `application/`

Coordinates business operations. A use case such as `PayOrder` validates the operation and requests one transaction through the abstract `TransactionRunner`. Application code never receives a SQLite database or transaction object.

### `domain/`

Plain Dart business concepts: entities, repository interfaces, value rules, and domain errors. This layer must be testable without Flutter or a device.

### `infrastructure/`

Concrete technical implementations: SQLite connection, migrations, SQL queries, transactions, backups, restore, and repository implementations.

The SQLite implementation of `TransactionRunner` creates one transaction-scoped repository set. Every repository call made by the callback uses the same SQLite transaction. This is the required mechanism for operations such as payment, order creation, item modification, and cancellation; opening independent repository transactions inside the callback is forbidden.

### `shared/`

Reusable code without ownership by one feature: money formatting, date formatting, generic widgets, validation helpers, and common result types.

## 4. State management

SQLite is the source of truth for persistent data. Use `ChangeNotifier` or `ValueNotifier` for initial screen state and controllers. Do not introduce a global state-management framework until the application demonstrates a real need.

After a write, explicitly reload or update the affected screen state. Do not maintain a second permanent copy of orders or catalog data in memory.

## 5. Database and migrations

- Keep migrations numbered and append-only.
- Never edit a migration that has shipped; add a new migration.
- Use `PRAGMA user_version` as the authoritative schema version. Do not store a second schema version in application settings.
- Run every pending migration and its `user_version` update atomically.
- Enable foreign keys on every connection.
- Use transactions for multi-table operations.
- Test migrations against a database containing data from the previous version.
- Use WAL only if the selected SQLite package supports it reliably on the target Android devices.

## 6. Required transactions

### Create an order

1. For `DINE_IN`, verify that the table is active and has no `OPEN` order.
2. Read and increment `settings.last_order_number` inside the transaction.
3. Insert the order with that business number and the table-name snapshot when applicable.
4. Commit the transaction.

The unique order-number and one-open-order-per-table constraints are final defenses against concurrent or repeated attempts.

### Pay an order

1. Verify that the order is still `OPEN`.
2. Verify that no payment exists.
3. Verify that the order contains at least one item and calculate the current total.
4. Insert the payment with `amount_cents` equal to that total.
5. Update the order to `PAID` and set `paid_at`.
6. Commit the transaction.

The unique payment-per-order constraint is a second defense against duplicate payments.

### Modify an order

Verify that the order remains `OPEN`. Changing order items and updating the order total must happen in the same transaction. Repositories must reject item or total mutations for `PAID` and `CANCELLED` orders even if the UI attempts them.

### Cancel an order

Validate `OPEN`, record the reason and timestamp, and change the order to `CANCELLED` in one transaction.

### Deactivate a table

Verify that the table has no `OPEN` order before marking it inactive. The operation must fail with a typed domain error if the table is occupied.

## 7. Identifiers, dates, and reporting

- Generate internal entity IDs as UUIDs in the application before persistence.
- Store timestamps as ISO-8601 UTC text with a `Z` suffix and compare them lexicographically only after canonical formatting is guaranteed.
- Treat `paid_at` as the sale timestamp for history and every report.
- Convert local calendar periods in `America/El_Salvador` to half-open UTC intervals `[start, end)` before querying SQLite.
- Weeks start on Monday. A custom end date includes that full local calendar date by using the start of the following day as the exclusive bound.
- Convert `paid_at` to the cafe timezone before grouping sales by hour.

## 8. Testing strategy

- Test domain entities and use cases with in-memory repository fakes.
- Test SQLite repositories against a temporary database.
- Test transaction rollback with a failure injected between related writes.
- Test order-number allocation and repeated payment attempts at repository level.
- Test report boundaries around local midnight, week boundaries, and inclusive custom end dates.
- Test Flutter widgets with mocked use cases or repositories.
- Test critical Android flows with `integration_test`.
- Validate final behavior on an emulator and the target physical tablet.

## 9. Backup and restore

- Never export by copying only the main database file while a connection or WAL may contain uncheckpointed data.
- During Milestone 0, select a SQLite-compatible snapshot mechanism supported on the target Android version. Prefer the SQLite online-backup API or `VACUUM INTO`; otherwise close all connections under an application-wide database lock before copying the complete database state.
- Write exports to a temporary app-owned file first, validate them, then hand the completed file to Android storage through the selected Storage Access Framework package.
- Import a restore candidate into temporary app-owned storage. Before replacing current data, verify its file header, supported `PRAGMA user_version`, required tables, `PRAGMA integrity_check`, and `PRAGMA foreign_key_check`.
- Create and verify a preventive backup of the current database before replacement.
- Close active connections, replace the database under the same application-wide lock, reopen it, run pending supported migrations, and verify integrity again.
- If any validation or replacement step fails, preserve or restore the original database and report a recoverable error.

## 10. Future expansion

If the cafe later needs multiple devices, the repository interfaces can receive HTTP implementations backed by a local server. This does not make the migration automatic: the future phase still needs a central database, concurrency control, authentication, conflict handling, and data migration.
