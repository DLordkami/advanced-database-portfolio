SET search_path = marketplace;
BEGIN;
SELECT stock_qty AS s FROM products WHERE product_id = 1 FOR UPDATE \gset
\echo [A] locked row, read stock = :s
SELECT pg_sleep(3) \g /dev/null
UPDATE products SET stock_qty = :s - 3 WHERE product_id = 1;
\echo [A] wrote stock = read value - 3
COMMIT;
