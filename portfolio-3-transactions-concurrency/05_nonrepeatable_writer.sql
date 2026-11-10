SET search_path = marketplace;
SELECT pg_sleep(1) \g /dev/null
UPDATE products SET unit_price = 1111.00 WHERE product_id = 3;
\echo [Writer] price changed to 1111.00 and committed
