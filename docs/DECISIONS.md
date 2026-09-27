# Architecture Decisions

## Decision 1 — Flutter instead of React/Capacitor

The product is a new, mobile-first Android tablet application. Flutter provides a dedicated mobile UI toolkit, strong control over touch layouts, and a consistent rendering model. The project also avoids carrying a web stack, WebView-specific behavior, or a React-to-mobile migration.

The trade-off is learning Dart and Flutter. That trade-off is intentional because the owner prefers Flutter and the project has not yet accumulated application code worth migrating.

## Decision 2 — One tablet and one SQLite database

The business currently needs one device. A single local database avoids synchronization conflicts, duplicate payments, and offline merge logic. Multiple devices will be addressed only when the business actually requires them.

## Decision 3 — Repository interfaces

Application code depends on repository contracts rather than SQLite classes. This keeps business rules testable and leaves room for a future local-server implementation without pretending that migration will be automatic.

## Decision 4 — No global state-management framework initially

SQLite is the persistent source of truth. Flutter `ChangeNotifier` or `ValueNotifier` is sufficient for the initial screen state. A larger state-management framework can be introduced when actual complexity justifies it.

## Decision 5 — Explicit transactions

Payment insertion and order status changes must commit or roll back together. Financial consistency is more important than minimizing a few lines of code.

## Decision 6 — No ORM in the MVP

The schema is small, SQL queries are understandable, and explicit migrations make backup and restoration behavior easier to reason about. An ORM or code generator can be reconsidered if query volume or schema complexity grows.
