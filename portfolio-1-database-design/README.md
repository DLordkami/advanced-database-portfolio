# Portfolio 1: Database Design and Modelling

**Student:** ACHEDE GODWIN (301907619) | **Course:** MIT 8103 Advanced Database Systems | **DBMS:** PostgreSQL 16

## 1. Selected case study

**Organisation / scenario:** *Kasuwa Demo Marketplace*, a simulated online marketplace connecting small vendors in Abuja with local customers. All data is invented; no real business or customer data is used.

**Nature of the system:** vendors list products, customers place orders, pay, and receive deliveries.

**Users of the database:** customers, vendors, delivery riders, marketplace administrators, and finance staff (reconciliation).

**Major data stored:** areas, categories, vendors, customers, products, orders and order items, payments, deliveries, reviews, and an inventory log.

**Key operations supported:** register vendors and customers; list and search products; place an order and reduce stock; record payment; assign and track delivery; review products; report sales per vendor and area.

## 2. Files

| File | Purpose |
|---|---|
| `schema.sql` | Complete DDL: tables, primary/foreign keys, CHECK/UNIQUE constraints, FK indexes |
| `er-diagram.mmd` | Mermaid source of the ER diagram |
| `ACHEDE_GODWIN_301907619_ER_Diagram.png` | Rendered ER diagram |
| `ACHEDE_GODWIN_301907619_Schema_Evidence.txt` | `psql` output proving the schema was created |

**To reproduce:** `createdb kasuwa_demo && psql -d kasuwa_demo -f schema.sql`

## 3. Relational schema summary

11 tables in the `marketplace` schema: `areas`, `categories` (self-referencing hierarchy), `vendors`, `customers`, `products`, `orders`, `order_items` (composite PK), `payments`, `deliveries` (1:1 with orders), `reviews`, `inventory_log`.

**Constraints used:** primary keys on every table; foreign keys for every relationship; `UNIQUE` on emails, payment reference, and (customer, product) review pairs; `CHECK` on prices (> 0), stock (>= 0), quantity (> 0), rating (1 to 5), and all status columns (enumerated values); `NOT NULL` wherever a value is mandatory.

## 4. Normalisation explanation

**Unnormalised starting point.** A single flat order sheet such as: `order_id, customer_name, customer_email, customer_area, product_name, vendor_name, vendor_area, category, qty, price, payment_method, payment_ref, rider`. This repeats customer, vendor, and product details on every line.

**1NF:** every column holds one atomic value and each row is identifiable. Repeating groups (several products per order) were moved to separate rows, in `order_items`, keyed by (`order_id`, `product_id`).

**2NF:** no partial dependency on part of a composite key. In `order_items` the only non-key attributes (`quantity`, `unit_price`) depend on the *whole* (`order_id`, `product_id`) key. Product name, vendor, and category depend only on `product_id`, so they live in `products`. Order date and status depend only on `order_id`, so they live in `orders`.

**3NF:** no transitive dependencies. Examples: customer name and email depend on `customer_id`, not on `order_id`, so they stay in `customers`. An area's district depends on `area_id`, not on a vendor or customer, so `areas` is a separate table. A category's parent depends on `category_id`, so it sits in `categories`.

**Deliberate denormalisation (documented):** `order_items.unit_price` copies the product price at purchase time. This is not redundancy by accident: if a vendor later changes `products.unit_price`, historical orders must keep the price the customer actually paid. It is an intentional snapshot, not a 3NF violation, because it records a *different fact* (the price at sale time).

**Result:** all tables are in 3NF (and BCNF, since every determinant is a candidate key).

## 5. Design choices and trade-offs

- `NUMERIC(12,2)` for money to avoid floating-point rounding errors.
- Status columns use `CHECK` constraints instead of free text, so invalid states cannot be stored.
- `payments` is separate from `orders` (1:many) so a failed payment can be retried without losing history.
- PostgreSQL does not index foreign keys automatically, so the join-heavy ones were indexed up front; further indexes are justified with execution plans in Portfolio 2.
