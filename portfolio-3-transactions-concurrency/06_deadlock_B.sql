\set ON_ERROR_STOP on
SET search_path = marketplace;
BEGIN;
UPDATE products SET stock_qty = stock_qty WHERE product_id = 2;
\echo [B] locked product 2
SELECT pg_sleep(1) \g /dev/null
UPDATE products SET stock_qty = stock_qty WHERE product_id = 1;
\echo [B] locked product 1
COMMIT;
