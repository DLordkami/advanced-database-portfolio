# Advanced Database Systems Portfolio (MIT 8103)

**Student:** ACHEDE GODWIN | **Student ID:** 301907619 | **Programme:** Master of Information Technology, 2026/2027 First Semester CA

## Case study
**Kasuwa Demo Marketplace**: a simulated online marketplace connecting small vendors in Abuja with local customers. All data in this repository is invented. The same case study is used in all five portfolio activities.

## Repository structure
| Folder | Activity | Key evidence |
|---|---|---|
| [`portfolio-1-database-design`](portfolio-1-database-design) | Database design and modelling | ER diagram, 11-table PostgreSQL schema in 3NF, keys and constraints, normalisation write-up |
| [`portfolio-2-query-optimisation`](portfolio-2-query-optimisation) | Query processing and optimisation | About 580,000 seeded rows, 5 queries, `EXPLAIN ANALYZE` plans before and after indexing, materialized view |
| [`portfolio-3-transactions-concurrency`](portfolio-3-transactions-concurrency) | Transactions and concurrency | COMMIT/ROLLBACK/SAVEPOINT, lost update, row locking, isolation levels, deadlock (two live sessions) |
| [`portfolio-4-nosql`](portfolio-4-nosql) | NoSQL and advanced data models | MongoDB document model on Atlas, validation, aggregations, indexes with execution statistics |
| [`portfolio-5-distributed-cloud`](portfolio-5-distributed-cloud) | Distributed and cloud database | Atlas 3-node replica set (AWS Frankfurt), write concern, read preference, consistency test, sharding plan |

Each folder has its own `README.md` explaining what was done, how to reproduce it and what the evidence shows, plus the scripts and the real output files.

## Headline results
- **P2:** indexes cut query time by 11x to 59x, and one query showed that an index does not always help (a materialized view fixed it instead).
- **P3:** a lost update left stock at 7 instead of 3; `SELECT ... FOR UPDATE` and `REPEATABLE READ` both fixed it; a deadlock was detected and resolved.
- **P4:** documents examined fell from 5,000 to 333 and from 3,000 to 4 after indexing.
- **P5:** majority writes cost about 26% more latency than `w:1`; with `w:1` and secondary reads, 5 of 200 reads were stale, against 0 of 200 with majority settings.

## Technology
PostgreSQL 16 (Portfolios 1 to 3), MongoDB 8 on MongoDB Atlas (Portfolios 4 and 5), `psql` and `mongosh`, accessed from a Hetzner cloud server.

## Notes on how the work was done
- **Timeline:** the portfolios were committed one at a time as each was completed, between 9 and 15 November 2026. The work was done in a compressed period because of work commitments.
- **Environment:** the MongoDB work first targeted a Hetzner server, where MongoDB would not start because of a kernel incompatibility. The install was removed cleanly and the work moved to MongoDB Atlas. See `portfolio-4-nosql/README.md` and `portfolio-5-distributed-cloud/README.md`.
- **Security:** no passwords or connection secrets are stored in this repository.

## AI use declaration
**Tool:** Claude (Anthropic). **What I used it for:** planning the portfolio, drafting my SQL and MongoDB scripts and README text, and debugging server and Atlas commands. **Who ran what:** the Portfolio 1 to 3 scripts were run by Claude in a PostgreSQL 16 cloud sandbox, and the outputs were provided to me for this repository. I ran the Portfolio 4 and 5 scripts myself, from my own server against my own MongoDB Atlas cluster. **How I checked it:** I reviewed the material before committing it, and I am responsible for its accuracy and for explaining it. My full declaration is in my submitted documentation.
