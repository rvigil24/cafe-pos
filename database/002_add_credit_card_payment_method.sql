CREATE TABLE payments_v2 (
  id TEXT PRIMARY KEY NOT NULL,
  order_id TEXT NOT NULL UNIQUE,
  method TEXT NOT NULL CHECK (method IN ('CASH', 'TRANSFER', 'CREDIT_CARD')),
  amount_cents INTEGER NOT NULL CHECK (amount_cents >= 0),
  received_cents INTEGER,
  reference TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (order_id) REFERENCES orders(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CHECK (
    (method = 'CASH' AND received_cents IS NOT NULL AND received_cents >= amount_cents)
    OR (method = 'TRANSFER' AND received_cents IS NULL)
    OR (
      method = 'CREDIT_CARD'
      AND received_cents IS NULL
      AND reference IS NULL
    )
  )
);

INSERT INTO payments_v2 (
  id,
  order_id,
  method,
  amount_cents,
  received_cents,
  reference,
  created_at
)
SELECT
  id,
  order_id,
  method,
  amount_cents,
  received_cents,
  reference,
  created_at
FROM payments;

DROP TABLE payments;

ALTER TABLE payments_v2 RENAME TO payments;

CREATE INDEX payments_created_at_idx ON payments(created_at);
CREATE INDEX payments_method_idx ON payments(method);
