# Product Requirements Document — Cafe POS MVP

## 1. Objective

Build an offline-first point-of-sale application for a small cafe. It runs on one Android tablet and does not depend on internet access.

The cafe charges customers after they consume. Orders must therefore remain open and editable until payment.

## 2. Users

### Tablet operator

- Open an order.
- Assign a table or mark it as takeaway.
- Add products, quantities, and notes.
- Take cash or record a manually verified transfer.
- Review open orders and completed sales.
- Manage products, categories, and tables.
- Change prices and availability.
- Cancel open orders.
- Export and restore backups.
- Access reports and settings.

The MVP does not authenticate or distinguish individual users. Anyone with physical access to the tablet can use all application functions.

## 3. Functional scope

### 3.1 Products and categories

- Create, edit, reorder, and deactivate categories.
- Deactivating a category hides it and its products from order entry without changing product flags or history; reactivating it restores products that remain individually active.
- Create, edit, and deactivate products.
- Display products alphabetically within each category; manual product reordering is not part of the MVP.
- Define product name, category, and price.
- Mark a product available or temporarily sold out.
- Model each independently priced variant as a separate sellable product in the MVP.
- Preserve historical product names, categories, and prices in order items.

### 3.2 Tables

- Create, rename, reorder, and deactivate tables.
- Do not allow an occupied table to be deactivated.
- Show each active table as free or occupied.
- Allow at most one `OPEN` order per table.
- Preserve the original table name in historical orders.

### 3.3 Orders

- Create `DINE_IN` and `TAKEAWAY` orders.
- Require a table for `DINE_IN` and forbid one for `TAKEAWAY`.
- Add products, quantities, and notes.
- Keep one order line per product. Adding the same product again increases that line's quantity at its existing price snapshot; its note applies to the whole line. Removing and later re-adding the product captures the then-current price.
- Change quantities or remove items while an order is `OPEN`.
- Once a product is sold out or inactive, keep any persisted line visible but forbid increasing its quantity; decreasing or removing it remains allowed.
- Persist every change immediately.
- Use only `OPEN`, `PAID`, and `CANCELLED` statuses.
- Allow only `OPEN` orders to be edited or paid.
- Preserve cancellation time and reason.

### 3.4 Payments

- Support `CASH` and manually verified `TRANSFER`.
- Allow at most one payment per order, and require exactly one payment for every `PAID` order.
- For cash, capture the amount received and calculate change.
- Reject cash below the order total.
- For transfers, allow an optional reference and require manual confirmation.
- Record the payment and change the order to `PAID` in one transaction.
- Set the persisted payment amount to the order total at the time of payment.
- Prevent duplicate payment after repeated taps or retries.
- Require at least one order item before payment. A zero total is valid when the order contains a zero-priced product.

### 3.5 Sales history

- List sales with date, order number, type, table, total, and payment method.
- Use the payment time (`paid_at`) as the sale date.
- Display product lines, quantities, prices, notes, and payment details.
- Search by order number.
- Filter by date range and payment method.
- Apply history date filters to `paid_at`.
- Keep paid sales read-only.

### 3.6 Reports

- Today, yesterday, this week, this month, and custom range.
- Net sales.
- Number of paid orders.
- Average ticket.
- Units sold.
- Best-selling products by units.
- Sales by category.
- Sales by hour.
- Totals by payment method.

Open and cancelled orders are excluded from sales. Product reports count `quantity`, not order lines.
Net sales are the sum of `payments.amount_cents` for `PAID` orders whose `paid_at` is in the selected period. Average ticket is net sales divided by the number of those paid orders.

Report periods are calculated in `America/El_Salvador` and converted to half-open UTC intervals `[start, end)` for database queries. A week starts on Monday. Custom ranges include the complete selected start and end calendar dates. Sales by hour use the local hour of `paid_at`.

### 3.7 Settings and backups

- Business name.
- Initial timezone: `America/El_Salvador`.
- Export a consistent SQLite backup using Android file storage.
- Validate and restore a compatible backup.
- Create a preventive backup before replacing the current database.

## 4. Business rules

- Store money as integer cents.
- Store timestamps as ISO-8601 UTC text with a `Z` suffix.
- Calculate order total as `quantity * unit_price_cents`.
- No taxes or discounts in the MVP.
- Copy product name, category, and price into `order_items` when added.
- Deactivating a product or table must not change history.
- Free a table when its open order is paid or cancelled.
- Only payments for `PAID` orders feed sales reports.
- A transfer is a manual record; the application does not verify a bank.
- Allocate each `order_number` atomically in the same transaction that creates its order. Internal IDs are UUIDs generated by the application.

## 5. Non-functional requirements

- Work completely in airplane mode.
- Preserve open orders after app close or device restart.
- Use large, touch-friendly controls.
- Preserve data integrity if the app closes during a payment.
- Preserve data through APK updates.
- Run incremental migrations without deleting existing data.
- Keep common local operations perceptually immediate.

## 6. Out of scope

Multiple devices, synchronization, backend/cloud services, ingredient inventory, recipes, expenses, accounting, fiscal invoices, printing, bank integrations, split payments, tips, discounts, authentication, role-based access control, individual accounts, loyalty, reservations, delivery, and kitchen display.
