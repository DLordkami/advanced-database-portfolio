\set ON_ERROR_STOP on
SET search_path = marketplace;
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT stock_qty AS s FROM products WHERE product_id = 1 \gset
\echo [A] read stock = :s
SELECT pg_sleep(3) \g /dev/null
UPDATE products SET stock_qty = :s - 3 WHERE product_id = 1;
COMMIT;
