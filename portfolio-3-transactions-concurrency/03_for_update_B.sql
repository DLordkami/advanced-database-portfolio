SET search_path = marketplace;
BEGIN;
SELECT stock_qty AS s FROM products WHERE product_id = 1 FOR UPDATE \gset
\echo [B] locked row, read stock = :s
SELECT pg_sleep(1) \g /dev/null
UPDATE products SET stock_qty = :s - 4 WHERE product_id = 1;
\echo [B] wrote stock = read value - 4
COMMIT;
