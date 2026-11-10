# Portfolio 3: Transactions and Concurrency

**Student:** ACHEDE GODWIN (301907619) | **DBMS:** PostgreSQL 16 | **Case study:** Kasuwa Demo Marketplace

All demos run against the schema (Portfolio 1) and data (Portfolio 2). Demos 2 to 6 use **two simultaneous psql sessions** (A and B), launched by `run_concurrency_demos.sh`, with `pg_sleep` used to force a specific interleaving.

**Reproduce:** `psql -d kasuwa_demo -a -f 01_commit_rollback.sql` and `PGPORT=5432 ./run_concurrency_demos.sh`

## Evidence files
| File | Content |
|---|---|
| `ACHEDE_GODWIN_301907619_Commit_Rollback_Evidence.txt` | Output of Demo 1 |
| `ACHEDE_GODWIN_301907619_Concurrency_Evidence.txt` | Output of Demos 2 to 6 |

## Demo 1: Atomicity (COMMIT, ROLLBACK, SAVEPOINT)
Placing an order is several steps: insert the order, insert the items, reduce stock, write the inventory log.
- **(a) Success:** all four steps commit together; stock falls from 5 to 3.
- **(b) Failure:** a customer orders 8 units of a product with 5 in stock. The `CHECK (stock_qty >= 0)` constraint rejects the stock update, and `ROLLBACK` undoes the order and order-item rows that had already been inserted. Evidence: stock is still 5 and the number of orders added is 0.
- **(c) SAVEPOINT:** a failing step is rolled back to a savepoint while earlier work in the same transaction is kept and committed.

## Demo 2: Lost update (the problem)
Two customers buy the last of the stock at the same time. Each session reads the stock (10), computes a new value in application code, and writes it back (A writes 10-3, B writes 10-4). B commits first; A then overwrites it.
**Result: stock = 7. Correct answer: 3.** B's purchase silently disappeared. This is allowed at the default READ COMMITTED level because each statement is valid on its own.

## Demo 3: Fix with row lock (SELECT ... FOR UPDATE)
Same scenario, but the read uses `FOR UPDATE`. B must wait for A's lock; when A commits, B reads the new value (7) and writes 7-4. **Result: stock = 3 (correct).** Trade-off: B waits, so throughput drops on hot rows.

## Demo 4: Fix with REPEATABLE READ (optimistic approach)
Same scenario with no explicit lock but `ISOLATION LEVEL REPEATABLE READ`. B commits first; when A tries to update the row that changed after its snapshot, PostgreSQL aborts A with `could not serialize access due to concurrent update`. **Result: stock = 6 (only B committed); A is rejected** and the application must retry the transaction. No wrong data is stored, but the application needs retry logic.

## Demo 5: Non-repeatable read (isolation levels)
A reader selects a product's price twice in one transaction while a writer changes the price in between.
| Isolation level | First read | Second read |
|---|---|---|
| READ COMMITTED | 2500.00 | **1111.00** (non-repeatable read) |
| REPEATABLE READ | 2500.00 | 2500.00 (stable snapshot) |

## Demo 6: Deadlock
A locks product 1 then wants product 2; B locks product 2 then wants product 1. Each waits for the other. PostgreSQL detects the cycle after `deadlock_timeout` (1 s), aborts one session with `ERROR: deadlock detected` and lets the other finish. **Prevention:** always lock rows in the same order (for example ascending `product_id`); the application should also catch the error and retry.

## Summary of mechanisms
| Problem | Mechanism | Cost |
|---|---|---|
| Partial failure | Transactions: BEGIN / COMMIT / ROLLBACK / SAVEPOINT | None significant |
| Lost update | Pessimistic: `SELECT ... FOR UPDATE` | Waiting, lower throughput |
| Lost update | Optimistic: REPEATABLE READ + retry | Aborted transactions to retry |
| Non-repeatable read | REPEATABLE READ snapshot | Possible serialization errors |
| Deadlock | Consistent lock ordering + retry | Developer discipline |

**Note:** in the deadlock evidence, lines from sessions A and B can appear interleaved because both run at the same time; this is expected.
