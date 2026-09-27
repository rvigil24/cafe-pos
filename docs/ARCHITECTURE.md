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
  domain/
    entities/
      product.dart
      order.dart
      order_item.dart
      payment.dart
      cafe_table.dart
    repositories/
      product_repository.dart
      order_repository.dart
      payment_repository.dart
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
    database/
      migrations/
      sqlite/
    repositories/
      sqlite_product_repository.dart
      sqlite_order_repository.dart
      sqlite_payment_repository.dart
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

Coordinates business operations. A use case such as `PayOrder` validates the operation, calls repositories, and controls the transaction boundary.

### `domain/`

Plain Dart business concepts: entities, repository interfaces, value rules, and domain errors. This layer must be testable without Flutter or a device.

### `infrastructure/`

Concrete technical implementations: SQLite connection, migrations, SQL queries, transactions, backups, restore, and repository implementations.

### `shared/`

Reusable code without ownership by one feature: money formatting, date formatting, generic widgets, validation helpers, and common result types.

## 4. State management

SQLite is the source of truth for persistent data. Use `ChangeNotifier` or `ValueNotifier` for initial screen state and controllers. Do not introduce a global state-management framework until the application demonstrates a real need.

After a write, explicitly reload or update the affected screen state. Do not maintain a second permanent copy of orders or catalog data in memory.

## 5. Database and migrations

- Keep migrations numbered and append-only.
- Never edit a migration that has shipped; add a new migration.
- Enable foreign keys on every connection.
- Use transactions for multi-table operations.
- Test migrations against a database containing data from the previous version.
- Use WAL only if the selected SQLite package supports it reliably on the target Android devices.

## 6. Required transactions

### Pay an order

1. Verify that the order is still `OPEN`.
2. Verify that no payment exists.
3. Read or calculate the current total.
4. Insert the payment.
5. Update the order to `PAID` and set `paid_at`.
6. Commit the transaction.

The unique payment-per-order constraint is a second defense against duplicate payments.

### Modify an order

Changing order items and updating the order total must happen in the same transaction.

### Cancel an order

Validate `OPEN`, record the reason and timestamp, and change the order to `CANCELLED` in one transaction.

## 7. Testing strategy

- Test domain entities and use cases with in-memory repository fakes.
- Test SQLite repositories against a temporary database.
- Test Flutter widgets with mocked use cases or repositories.
- Test critical Android flows with `integration_test`.
- Validate final behavior on an emulator and the target physical tablet.

## 8. Future expansion

If the cafe later needs multiple devices, the repository interfaces can receive HTTP implementations backed by a local server. This does not make the migration automatic: the future phase still needs a central database, concurrency control, authentication, conflict handling, and data migration.
