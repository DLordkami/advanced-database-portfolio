\set ON_ERROR_STOP on
SET search_path = marketplace;
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT stock_qty AS s FROM products WHERE product_id = 1 \gset
\echo [B] read stock = :s
SELECT pg_sleep(1) \g /dev/null
UPDATE products SET stock_qty = :s - 4 WHERE product_id = 1;
COMMIT;
