SET search_path = marketplace;
-- Q1: composite index, status equality first then range on date
CREATE INDEX idx_orders_status_date ON orders(status, ordered_at);
-- Q2: exact-match search on product name
CREATE INDEX idx_products_name ON products(product_name);
-- Q3: join from order_items to products (PK is (order_id, product_id), so product_id alone is not indexed)
CREATE INDEX idx_order_items_product ON order_items(product_id);
-- Q4: partial composite index serves filter + ORDER BY without a sort
CREATE INDEX idx_products_cat_price_active ON products(category_id, unit_price) WHERE is_active;
ANALYZE;
