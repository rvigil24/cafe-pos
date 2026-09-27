PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS categories (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL COLLATE NOCASE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS categories_active_name_uq
ON categories(name)
WHERE is_active = 1;

CREATE TABLE IF NOT EXISTS products (
  id TEXT PRIMARY KEY NOT NULL,
  category_id TEXT NOT NULL,
  name TEXT NOT NULL COLLATE NOCASE,
  price_cents INTEGER NOT NULL CHECK (price_cents >= 0),
  is_available INTEGER NOT NULL DEFAULT 1 CHECK (is_available IN (0, 1)),
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories(id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS products_category_idx ON products(category_id);
CREATE INDEX IF NOT EXISTS products_active_available_idx ON products(is_active, is_available);

CREATE TABLE IF NOT EXISTS cafe_tables (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL COLLATE NOCASE,
  sort_order INTEGER NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0, 1)),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS cafe_tables_active_name_uq
ON cafe_tables(name)
WHERE is_active = 1;

CREATE TABLE IF NOT EXISTS orders (
  id TEXT PRIMARY KEY NOT NULL,
  order_number INTEGER NOT NULL UNIQUE CHECK (order_number > 0),
  table_id TEXT,
  table_name_snapshot TEXT,
  type TEXT NOT NULL CHECK (type IN ('DINE_IN', 'TAKEAWAY')),
  status TEXT NOT NULL CHECK (status IN ('OPEN', 'PAID', 'CANCELLED')),
  total_cents INTEGER NOT NULL DEFAULT 0 CHECK (total_cents >= 0),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  paid_at TEXT,
  cancelled_at TEXT,
  cancellation_reason TEXT,
  FOREIGN KEY (table_id) REFERENCES cafe_tables(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CHECK (
    (type = 'DINE_IN' AND table_id IS NOT NULL AND table_name_snapshot IS NOT NULL)
    OR (type = 'TAKEAWAY' AND table_id IS NULL AND table_name_snapshot IS NULL)
  ),
  CHECK (
    (status = 'PAID' AND paid_at IS NOT NULL AND cancelled_at IS NULL AND cancellation_reason IS NULL)
    OR (
      status = 'CANCELLED'
      AND cancelled_at IS NOT NULL
      AND paid_at IS NULL
      AND cancellation_reason IS NOT NULL
      AND length(trim(cancellation_reason)) > 0
    )
    OR (
      status = 'OPEN'
      AND paid_at IS NULL
      AND cancelled_at IS NULL
      AND cancellation_reason IS NULL
    )
  )
);

CREATE UNIQUE INDEX IF NOT EXISTS one_open_order_per_table_uq
ON orders(table_id)
WHERE status = 'OPEN' AND table_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS orders_status_idx ON orders(status);
CREATE INDEX IF NOT EXISTS orders_created_at_idx ON orders(created_at);
CREATE INDEX IF NOT EXISTS orders_paid_at_idx ON orders(paid_at);

CREATE TABLE IF NOT EXISTS order_items (
  id TEXT PRIMARY KEY NOT NULL,
  order_id TEXT NOT NULL,
  product_id TEXT,
  product_name_snapshot TEXT NOT NULL,
  category_name_snapshot TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  unit_price_cents INTEGER NOT NULL CHECK (unit_price_cents >= 0),
  note TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  FOREIGN KEY (product_id) REFERENCES products(id) ON UPDATE CASCADE ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS order_items_order_idx ON order_items(order_id);
CREATE INDEX IF NOT EXISTS order_items_product_idx ON order_items(product_id);
CREATE UNIQUE INDEX IF NOT EXISTS one_line_per_product_per_order_uq
ON order_items(order_id, product_id)
WHERE product_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS payments (
  id TEXT PRIMARY KEY NOT NULL,
  order_id TEXT NOT NULL UNIQUE,
  method TEXT NOT NULL CHECK (method IN ('CASH', 'TRANSFER')),
  amount_cents INTEGER NOT NULL CHECK (amount_cents >= 0),
  received_cents INTEGER,
  reference TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CHECK (
    (method = 'CASH' AND received_cents IS NOT NULL AND received_cents >= amount_cents)
    OR (method = 'TRANSFER' AND received_cents IS NULL)
  )
);

CREATE INDEX IF NOT EXISTS payments_created_at_idx ON payments(created_at);
CREATE INDEX IF NOT EXISTS payments_method_idx ON payments(method);

CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY NOT NULL,
  value TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

INSERT OR IGNORE INTO settings(key, value, updated_at)
VALUES
  ('timezone', 'America/El_Salvador', strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  ('business_name', 'Cafetería', strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  ('last_order_number', '0', strftime('%Y-%m-%dT%H:%M:%fZ', 'now'));

PRAGMA user_version = 1;
