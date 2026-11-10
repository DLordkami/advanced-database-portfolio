-- Portfolio 2: synthetic data for Kasuwa Demo Marketplace (all invented)
SET search_path = marketplace;
SELECT setseed(0.42);   -- reproducible random data

INSERT INTO areas(area_name, district)
SELECT n, d FROM (VALUES
 ('Wuse','AMAC'),('Garki','AMAC'),('Maitama','AMAC'),('Asokoro','AMAC'),('Gwarinpa','AMAC'),
 ('Lugbe','AMAC'),('Kubwa','Bwari'),('Jabi','AMAC'),('Utako','AMAC'),('Nyanya','AMAC')) t(n,d);

INSERT INTO categories(category_name) VALUES
 ('Fashion'),('Electronics'),('Groceries'),('Home & Kitchen'),('Beauty'),('Phones'),('Books'),('Sports');

INSERT INTO vendors(business_name,email,phone,area_id,status,joined_at)
SELECT 'Vendor '||g, 'vendor'||g||'@demo.test', '0803'||lpad(g::text,7,'0'),
       1+(random()*9)::int, (ARRAY['active','active','active','pending','suspended'])[1+(random()*4)::int],
       now() - (random()*700||' days')::interval
FROM generate_series(1,500) g;

INSERT INTO customers(full_name,email,phone,area_id,created_at)
SELECT 'Customer '||g, 'cust'||g||'@demo.test', '0805'||lpad(g::text,7,'0'),
       1+(random()*9)::int, now() - (random()*700||' days')::interval
FROM generate_series(1,20000) g;

INSERT INTO products(vendor_id,category_id,product_name,description,unit_price,stock_qty,is_active,created_at)
SELECT 1+(random()*499)::int, 1+(random()*7)::int, 'Product '||g,
       'Demo description for product '||g, round((500+random()*99500)::numeric,2),
       (random()*200)::int, random()>0.05, now() - (random()*700||' days')::interval
FROM generate_series(1,20000) g;

INSERT INTO orders(customer_id,delivery_area_id,status,ordered_at)
SELECT 1+(random()*19999)::int, 1+(random()*9)::int,
       (ARRAY['pending','paid','paid','shipped','delivered','delivered','delivered','cancelled'])[1+(random()*7)::int],
       now() - (random()*365||' days')::interval
FROM generate_series(1,100000);

INSERT INTO order_items(order_id,product_id,quantity,unit_price)
SELECT o, p, 1+(random()*4)::int, pr.unit_price
FROM (SELECT o, 1+(random()*19999)::int AS p FROM generate_series(1,100000) o, generate_series(1,3) k) x
JOIN products pr ON pr.product_id = x.p
ON CONFLICT DO NOTHING;

INSERT INTO payments(order_id,amount,method,status,reference,paid_at)
SELECT o.order_id,
       (SELECT sum(quantity*unit_price) FROM order_items i WHERE i.order_id=o.order_id),
       (ARRAY['card','transfer','ussd','cash'])[1+(random()*3)::int],
       CASE WHEN o.status='cancelled' THEN 'failed' WHEN o.status='pending' THEN 'pending' ELSE 'success' END,
       'REF'||lpad(o.order_id::text,10,'0'), o.ordered_at + interval '5 minutes'
FROM orders o
WHERE EXISTS (SELECT 1 FROM order_items i WHERE i.order_id=o.order_id);

INSERT INTO reviews(customer_id,product_id,rating,comment)
SELECT 1+(random()*19999)::int, 1+(random()*19999)::int, 1+(random()*4)::int, 'Demo review'
FROM generate_series(1,40000)
ON CONFLICT DO NOTHING;

ANALYZE;
