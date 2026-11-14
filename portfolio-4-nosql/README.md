# Portfolio 4: NoSQL and Advanced Data Models

**Student:** ACHEDE GODWIN (301907619) | **Case study:** Kasuwa Demo Marketplace (same as Portfolios 1 to 3; invented data only)
**Model type:** Document database (MongoDB 8) running on MongoDB Atlas (AWS Frankfurt), accessed with `mongosh` from a Hetzner cloud server.

## 1. Why a document model for this case study
In the relational design (Portfolio 1) every product shares the same columns. In a real marketplace they do not: a phone has RAM, storage and battery; a grocery item has weight and shelf life; clothing has size and material. In SQL that means many NULL columns or an extra attribute table with joins. In MongoDB each product is one document that carries only its own attributes, so one collection holds all categories (see the sample documents in `ACHEDE_GODWIN_301907619_Seed_Output.txt`). Orders also fit well: an order is always read together with its items, so the items are stored inside the order document.

## 2. Data model
| Collection | Documents | Design decision |
|---|---|---|
| `vendors` | 200 | Separate collection, referenced by id |
| `products` | 5,000 | `attributes` sub-document differs per category; `tags` array; **embedded vendor snapshot** (`_id`, `name`, `area`) so a product page needs no join |
| `orders` | 3,000 | **Items embedded** as an array (name and price copied at purchase time); customer snapshot and payment embedded |
| `reviews` | 8,000 | **Referenced** by `product_id`, not embedded: reviews grow without limit, and a 16 MB document cap and ever-growing documents would hurt |

**Embed or reference?** Embed data that is read together and has bounded size (order items, vendor snapshot). Reference data that grows without bound or is shared and updated often (reviews, vendors). **Trade-off:** embedded copies (such as the vendor name inside a product) can become stale if the vendor changes its name, so the application must update them or accept the snapshot; the relational design avoids this duplication.

**Validation.** Documents are not schema-less here: a `$jsonSchema` validator on `products` requires name, category, price, stock and vendor, with `price >= 1` and `stock >= 0`. The seed script proves it: inserting a product with negative stock was refused with error 121 (`Document failed validation`).

## 3. Implementation evidence
| File | Content |
|---|---|
| `01_seed.js` -> `..._Seed_Output.txt` | Creates the collections and data; document counts; sample Phones and Groceries documents; validation test |
| `02_queries.js` -> `..._Queries_Output.txt` | Seven queries and their results |
| `03_indexes.js` -> `..._Indexes_Output.txt` | Execution statistics before and after indexes |

**Queries (all executed, see output file):**
1. Phones with at least 8 GB RAM, at least 128 GB storage, under 300,000, cheapest five: a query on flexible nested fields (`attributes.ram_gb`).
2. Perishable groceries tagged `sale`: array plus nested field (121 matches).
3. Top five vendors by revenue from delivered orders: aggregation pipeline `$match`, `$unwind`, `$group`, `$sort`, `$limit` (vendor 85 first, about 24.5 million).
4. Sales per delivery area and month: `$group` with `$dateToString`.
5. Best-reviewed products: `$group` on reviews, then `$lookup` to products (MongoDB's join).
6. **Atomic stock update:** `updateOne({_id, stock: {$gte: 3}}, {$inc: {stock: -3}})`. The first purchase succeeded (stock 5 to 2); the second (3 of 2) modified nothing. The condition and update happen atomically, so stock cannot go negative.
7. Updating one element inside an embedded array with `arrayFilters`.

## 4. Indexing and performance
| Query | Before | After |
|---|---|---|
| Phones filtered, sorted by price | `COLLSCAN`, 5,000 docs examined | `IXSCAN`, **333** examined, 121 returned |
| Orders of customer 77, newest first | `COLLSCAN`, 3,000 docs examined | `IXSCAN`, **4** examined, 4 returned |

Indexes created: `{category, price}`, `{category, attributes.ram_gb}`, `{customer._id, ordered_at}` and a text index on `name`.

**Analysis.** The documents-examined figure is the meaningful measure: the order lookup went from reading every order to reading exactly the four that matter. The millisecond times (4 to 3 ms and 2 to 1 ms) are almost equal because the data set is tiny; on a large collection the difference would grow with size. The planner chose the `{category, price}` index for the phone query and read 333 phones before applying the RAM filter, so the `{category, attributes.ram_gb}` index was not chosen for it. Unused indexes still cost write time and storage, so in production I would keep only the indexes that queries actually use. A first version of the text-search test returned all 5,000 products, because a plain multi-word text search matches any word and every product name contains "item"; searching for the exact phrase fixed it (1 result).

## 5. Relational (Portfolios 1 to 3) against document (this portfolio)
| Aspect | PostgreSQL | MongoDB |
|---|---|---|
| Variable product attributes | Many NULLs or extra tables | One flexible sub-document |
| Order plus items | Two tables and a join | One document |
| Referential integrity | Foreign keys enforce it | Application's job |
| Multi-table transactions | Native, strong | Possible on replica sets, but single-document atomicity is the usual design |
| Reports across entities | Strength of SQL joins | `$lookup` works but is heavier |

Best fit: PostgreSQL for money, stock and reconciliation; MongoDB for the product catalogue and flexible attributes.

## 6. Setup and challenges
- MongoDB runs on **Atlas** (free M0 cluster). I first tried to install it on a Hetzner server, but the server's Linux kernel version has a known incompatibility with that MongoDB build and `mongod` refused to start (a deliberate safety check). I removed the install cleanly and used Atlas; the Hetzner server runs only `mongosh` as the client.
- Ubuntu 26.04 also had no official MongoDB package, which was the first sign of trouble.
- **Limitations:** free tier is 512 MB with shared resources, so performance numbers are small-scale. Multi-document transactions and sharding are not demonstrated here (see Portfolio 5 for replication and a sharding plan).
- Run order: `01_seed.js`, `02_queries.js`, `03_indexes.js`, each with `mongosh "<atlas-uri>" -u <user> -p <password> --file <script>`. The password is typed at run time and is not stored in the repository.
