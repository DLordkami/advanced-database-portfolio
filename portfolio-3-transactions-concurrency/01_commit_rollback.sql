-- Demo 1: atomic order placement. COMMIT on success, ROLLBACK on failure.
SET search_path = marketplace;
UPDATE products SET stock_qty = 5 WHERE product_id = 1;
UPDATE products SET stock_qty = 5 WHERE product_id = 2;
SELECT product_id, stock_qty FROM products WHERE product_id IN (1,2) ORDER BY 1;

\echo '--- (a) Successful order: all steps commit together'
BEGIN;
INSERT INTO orders(customer_id, delivery_area_id, status) VALUES (1, 1, 'paid') RETURNING order_id \gset
INSERT INTO order_items(order_id, product_id, quantity, unit_price)
  SELECT :order_id, product_id, 2, unit_price FROM products WHERE product_id = 1;
UPDATE products SET stock_qty = stock_qty - 2 WHERE product_id = 1;
INSERT INTO inventory_log(product_id, change_qty, reason) VALUES (1, -2, 'order');
COMMIT;
SELECT product_id, stock_qty FROM products WHERE product_id = 1;

\echo '--- (b) Failed order: product 2 has only 5 in stock, customer wants 8 -> CHECK (stock_qty >= 0) fails'
SELECT count(*) AS orders_before FROM orders \gset
BEGIN;
INSERT INTO orders(customer_id, delivery_area_id, status) VALUES (1, 1, 'paid') RETURNING order_id \gset
INSERT INTO order_items(order_id, product_id, quantity, unit_price)
  SELECT :order_id, product_id, 8, unit_price FROM products WHERE product_id = 2;
UPDATE products SET stock_qty = stock_qty - 8 WHERE product_id = 2;   -- ERROR here
ROLLBACK;
SELECT product_id, stock_qty FROM products WHERE product_id = 2;
SELECT count(*) - :orders_before AS orders_added_by_failed_attempt FROM orders;

\echo '--- (c) SAVEPOINT: undo only the failing part, keep the rest'
BEGIN;
UPDATE products SET stock_qty = stock_qty - 1 WHERE product_id = 1;
SAVEPOINT before_risky;
UPDATE products SET stock_qty = stock_qty - 99 WHERE product_id = 1;  -- ERROR
ROLLBACK TO SAVEPOINT before_risky;
COMMIT;
SELECT product_id, stock_qty FROM products WHERE product_id = 1;
