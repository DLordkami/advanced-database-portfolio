-- =====================================================================
-- MIT 8103 Advanced Database Systems - Portfolio 1
-- Case study: Kasuwa Demo Marketplace (simulated Abuja vendor marketplace)
-- Student: ACHEDE GODWIN (301907619)
-- DBMS: PostgreSQL 16
-- =====================================================================

DROP SCHEMA IF EXISTS marketplace CASCADE;
CREATE SCHEMA marketplace;
SET search_path = marketplace;

-- ---------------------------------------------------------------------
-- Reference tables
-- ---------------------------------------------------------------------
CREATE TABLE areas (
    area_id     SERIAL PRIMARY KEY,
    area_name   VARCHAR(80) NOT NULL UNIQUE,
    district    VARCHAR(80) NOT NULL
);

CREATE TABLE categories (
    category_id        SERIAL PRIMARY KEY,
    category_name      VARCHAR(80) NOT NULL UNIQUE,
    parent_category_id INT REFERENCES categories(category_id) ON DELETE SET NULL
);

-- ---------------------------------------------------------------------
-- Actors
-- ---------------------------------------------------------------------
CREATE TABLE vendors (
    vendor_id     SERIAL PRIMARY KEY,
    business_name VARCHAR(120) NOT NULL,
    email         VARCHAR(120) NOT NULL UNIQUE,
    phone         VARCHAR(20)  NOT NULL,
    area_id       INT NOT NULL REFERENCES areas(area_id),
    status        VARCHAR(12)  NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'active', 'suspended')),
    joined_at     TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    full_name   VARCHAR(120) NOT NULL,
    email       VARCHAR(120) NOT NULL UNIQUE,
    phone       VARCHAR(20)  NOT NULL,
    area_id     INT NOT NULL REFERENCES areas(area_id),
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Catalogue
-- ---------------------------------------------------------------------
CREATE TABLE products (
    product_id   SERIAL PRIMARY KEY,
    vendor_id    INT NOT NULL REFERENCES vendors(vendor_id),
    category_id  INT NOT NULL REFERENCES categories(category_id),
    product_name VARCHAR(150) NOT NULL,
    description  TEXT,
    unit_price   NUMERIC(12,2) NOT NULL CHECK (unit_price > 0),
    stock_qty    INT NOT NULL DEFAULT 0 CHECK (stock_qty >= 0),
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Orders and payments
-- ---------------------------------------------------------------------
CREATE TABLE orders (
    order_id         SERIAL PRIMARY KEY,
    customer_id      INT NOT NULL REFERENCES customers(customer_id),
    delivery_area_id INT NOT NULL REFERENCES areas(area_id),
    status           VARCHAR(12) NOT NULL DEFAULT 'pending'
                     CHECK (status IN ('pending', 'paid', 'shipped', 'delivered', 'cancelled')),
    ordered_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Composite primary key: a product appears once per order.
-- unit_price is copied at purchase time so later price changes do not
-- rewrite history (a deliberate, documented snapshot - not a 3NF violation).
CREATE TABLE order_items (
    order_id   INT NOT NULL REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT NOT NULL REFERENCES products(product_id),
    quantity   INT NOT NULL CHECK (quantity > 0),
    unit_price NUMERIC(12,2) NOT NULL CHECK (unit_price > 0),
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    order_id   INT NOT NULL REFERENCES orders(order_id),
    amount     NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    method     VARCHAR(12) NOT NULL CHECK (method IN ('card', 'transfer', 'ussd', 'cash')),
    status     VARCHAR(10) NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending', 'success', 'failed', 'refunded')),
    reference  VARCHAR(40) NOT NULL UNIQUE,
    paid_at    TIMESTAMPTZ
);

CREATE TABLE deliveries (
    delivery_id  SERIAL PRIMARY KEY,
    order_id     INT NOT NULL UNIQUE REFERENCES orders(order_id),   -- one delivery per order
    rider_name   VARCHAR(120),
    status       VARCHAR(12) NOT NULL DEFAULT 'assigned'
                 CHECK (status IN ('assigned', 'picked_up', 'delivered', 'failed')),
    delivered_at TIMESTAMPTZ
);

-- ---------------------------------------------------------------------
-- Feedback and audit
-- ---------------------------------------------------------------------
CREATE TABLE reviews (
    review_id   SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    product_id  INT NOT NULL REFERENCES products(product_id),
    rating      SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (customer_id, product_id)          -- one review per customer per product
);

CREATE TABLE inventory_log (
    log_id      BIGSERIAL PRIMARY KEY,
    product_id  INT NOT NULL REFERENCES products(product_id),
    change_qty  INT NOT NULL,
    reason      VARCHAR(30) NOT NULL,
    logged_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------
-- Foreign-key indexes (PostgreSQL does not create these automatically).
-- Further performance indexes are added and measured in Portfolio 2.
-- ---------------------------------------------------------------------
CREATE INDEX idx_products_vendor   ON products(vendor_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_orders_customer   ON orders(customer_id);
CREATE INDEX idx_payments_order    ON payments(order_id);
CREATE INDEX idx_reviews_product   ON reviews(product_id);
