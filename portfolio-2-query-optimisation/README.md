# Portfolio 2: Query Processing and Optimisation

**Student:** ACHEDE GODWIN (301907619) | **DBMS:** PostgreSQL 16 | **Case study:** Kasuwa Demo Marketplace

## What was done
1. `seed.sql` loads reproducible synthetic data (fixed random seed): 500 vendors, 20,000 customers, 20,000 products, 100,000 orders, ~300,000 order lines, 100,000 payments, ~40,000 reviews.
2. `queries.sql` holds 5 realistic marketplace queries, each run with `EXPLAIN (ANALYZE, BUFFERS)`.
3. Baseline plans were captured (`..._Plans_BEFORE.txt`), indexes were added (`optimise.sql`), and the same queries were re-run (`..._Plans_AFTER.txt`).
4. Q3 did not benefit from an index, so a materialized view was tested (`optimise_q3_matview.sql`, `..._Plan_Q3_MatView.txt`).

**Reproduce:** run `schema.sql` (Portfolio 1), `seed.sql`, `queries.sql`, `optimise.sql`, `queries.sql` again.

## Results (execution time, ms)

| Query | Purpose | Before | After | Change | Plan change |
|---|---|---|---|---|---|
| Q1 | Delivered orders in last 7 days | 10.175 | 0.898 | ~11x faster | Seq Scan -> Bitmap Index Scan on `idx_orders_status_date` |
| Q2 | Product lookup by exact name | 1.720 | 0.029 | ~59x faster | Seq Scan -> Index Scan on `idx_products_name` |
| Q3 | Top 10 vendors by revenue (4-table join) | 107.475 | 111.707 | none (index ignored) | Unchanged: seq scans + hash joins |
| Q3 (matview) | Same result from pre-computed view | 107.475 | 0.028 | ~3,800x faster | Index Scan on `idx_vendor_revenue` |
| Q4 | Active products in category, price range, cheapest first | 1.509 | 0.084 | ~18x faster | Bitmap scan + sort -> Index Scan on partial composite index (no sort) |
| Q5 | Items bought by one customer | 0.140 | 0.135 | none needed | Already used `idx_orders_customer` + PK lookups |

## Analysis

**Q1 (composite index).** The filter has an equality (`status`) and a range (`ordered_at`). Putting the equality column first and the range column second lets one index scan find exactly the matching rows, so reads dropped from the whole table to about 480 pages.

**Q2 (B-tree on a selective column).** An exact match returns one row out of 20,000. A sequential scan reads every row; the index jumps straight to it. Small in absolute terms here, but this grows linearly with table size without the index.

**Q3 (when an index does not help).** The new `idx_order_items_product` was not used. The query aggregates most of `order_items` (all orders with status `delivered`, about 40% of rows), and the planner correctly judged that reading the table sequentially and hash-joining is cheaper than hundreds of thousands of random index lookups. The result is that adding an index is not always an optimisation; the execution plan has to confirm it. The real fix for a read-heavy leaderboard is to pre-compute the aggregate. The materialized view returns the same top 10 in 0.028 ms. Trade-off: the data is only as fresh as the last `REFRESH MATERIALIZED VIEW`, so it suits a dashboard that tolerates slightly stale numbers, not a real-time balance.

**Q4 (partial composite index).** The index `(category_id, unit_price) WHERE is_active` is smaller than a full index (inactive products are excluded) and returns rows already sorted by price, which removes the sort step and lets `LIMIT 20` stop early.

**Q5 (already optimal).** Foreign-key indexes created in Portfolio 1 already covered this path, so no extra index was added. Not adding one avoids extra write cost.

**Index cost.** Every index slows `INSERT`/`UPDATE` and uses disk. Only indexes that a measured query actually uses were kept, which is why the Q3 index is reported honestly as ineffective.
