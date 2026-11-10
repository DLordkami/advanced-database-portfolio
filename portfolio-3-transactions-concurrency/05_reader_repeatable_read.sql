SET search_path = marketplace;
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT unit_price AS first_read FROM products WHERE product_id = 3;
SELECT pg_sleep(3) \g /dev/null
SELECT unit_price AS second_read FROM products WHERE product_id = 3;
COMMIT;
