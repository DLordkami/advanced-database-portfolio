SET search_path = marketplace;
-- Q3 reads most of order_items, so an index cannot help: a seq scan + hash join is the right plan.
-- Better fix for a read-heavy leaderboard: pre-compute the aggregate and refresh it on a schedule.
DROP MATERIALIZED VIEW IF EXISTS vendor_revenue;
CREATE MATERIALIZED VIEW vendor_revenue AS
SELECT v.vendor_id, v.business_name, sum(oi.quantity * oi.unit_price) AS revenue
FROM order_items oi
JOIN products p ON p.product_id = oi.product_id
JOIN vendors  v ON v.vendor_id  = p.vendor_id
JOIN orders   o ON o.order_id   = oi.order_id
WHERE o.status = 'delivered'
GROUP BY v.vendor_id, v.business_name;
CREATE INDEX idx_vendor_revenue ON vendor_revenue(revenue DESC);
ANALYZE vendor_revenue;

EXPLAIN (ANALYZE, BUFFERS)
SELECT vendor_id, business_name, revenue FROM vendor_revenue ORDER BY revenue DESC LIMIT 10;
