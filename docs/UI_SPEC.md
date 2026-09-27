# UI Specification

## 1. Principles

- Design first for an Android tablet in landscape orientation.
- Use touch targets of at least 48 × 48 dp.
- Keep the sales flow short and avoid long forms.
- Always show the saved state, current total, and primary action.
- Do not rely on hover interactions.
- Confirm destructive actions explicitly.
- Use Flutter Material 3 components consistently.

## 2. Main navigation

Sections:

1. Home
2. New order
3. Sales
4. Reports
5. Products
6. Settings

Use a persistent `NavigationRail` or an equivalent tablet-friendly navigation pattern. Keep the current order visible while editing it.

## 3. Screens

### Home

- Table cards showing `Free` or `Occupied`.
- Open takeaway orders in a separate section.
- Each order shows number, time, current total, and time open.
- Actions: open order and create order.

### New order / Edit order

Use two main areas:

- Left: categories and a grid of available products.
- Right: current order lines, quantities, notes, and total.

Actions:

- Add a product with one tap.
- Adding a product already present increases its existing line at the captured price; each product has at most one line and one line-level note.
- Increase or decrease quantity.
- Remove a line.
- Edit a note.
- Save and return.
- Proceed to payment.

Sold-out products may appear disabled. Inactive products and products in an inactive category must not appear.
If a product already in the order becomes sold out or inactive, keep the line visible and allow only decreasing or removing it.

### Payment

- Prominent total.
- Method selector: cash or transfer.
- Cash: amount received, calculated change, and validation.
- Transfer: optional reference and manual-verification confirmation.
- Disable the confirmation action while the transaction is running.
- On success, return to Home and free the table.

### Sales

- Descending list by payment date.
- Search by order number.
- Date and payment filters.
- Read-only detail view.

### Reports

- Period selector.
- Metrics: sales, paid orders, average ticket, and units.
- Best-selling products.
- Sales by category, hour, and payment method.
- Charts must include readable values and accessible labels.

### Products

- Category and product management sections.
- Create, edit, and deactivate categories and products.
- Reorder categories; list products alphabetically within each category.
- Explain that deactivating a category hides its products from order entry without deactivating them individually.
- Quick availability toggle.

### Settings

- Tables.
- Prevent deactivation of an occupied table and explain why the action is unavailable.
- Business name.
- Export backup.
- Restore backup with an explicit confirmation.

## 4. Required states

Every data screen must define:

- initial loading;
- empty state;
- recoverable error;
- success feedback;
- action in progress;
- destructive-action confirmation.

## 5. Accessibility

- Add semantic labels to icon-only buttons.
- Maintain sufficient contrast.
- Do not communicate state through color alone.
- Keep focus order coherent for an external keyboard.
- Associate validation errors with their fields.
