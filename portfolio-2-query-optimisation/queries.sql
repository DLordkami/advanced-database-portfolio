SET search_path = marketplace;

-- Q1: recent delivered orders (date-range filter)
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, customer_id, ordered_at
FROM orders
WHERE status = 'delivered' AND ordered_at >= now() - interval '7 days';

-- Q2: exact product lookup by name (search box)
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, product_name, unit_price, stock_qty
FROM products
WHERE product_name = 'Product 12345';

-- Q3: top 10 vendors by revenue (4-table join + aggregation)
EXPLAIN (ANALYZE, BUFFERS)
SELECT v.vendor_id, v.business_name, sum(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN vendors  v ON v.vendor_id  = p.vendor_id
JOIN orders   o ON o.order_id   = oi.order_id
WHERE o.status = 'delivered'
GROUP BY v.vendor_id, v.business_name
ORDER BY revenue DESC
LIMIT 10;

-- Q4: category browse: active products in a price range, cheapest first
EXPLAIN (ANALYZE, BUFFERS)
SELECT product_id, product_name, unit_price
FROM products
WHERE category_id = 3 AND is_active AND unit_price BETWEEN 5000 AND 20000
ORDER BY unit_price
LIMIT 20;

-- Q5: all items a customer has ever bought (join through orders)
EXPLAIN (ANALYZE, BUFFERS)
SELECT o.order_id, p.product_name, oi.quantity
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
WHERE o.customer_id = 777
ORDER BY o.ordered_at DESC;
