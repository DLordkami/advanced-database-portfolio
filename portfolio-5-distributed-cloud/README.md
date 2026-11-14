# Portfolio 5: Distributed and Cloud Database Exercise

**Student:** ACHEDE GODWIN (301907619) | **Case study:** Kasuwa Demo Marketplace (invented data only)

## 1. What was deployed
| Item | Detail |
|---|---|
| Database service | MongoDB Atlas, free (M0) cluster `Cluster0`, MongoDB 8 |
| Cloud / region | AWS, Frankfurt (`eu-central-1`) |
| Topology | **3-node replica set** `atlas-v94fzd-shard-0`: 1 primary + 2 secondaries, one in each of three availability zones (`euc1-az1`, `euc1-az2`, `euc1-az3`) |
| Client machine | A Hetzner cloud server (Nuremberg) that connects over TLS using `mongosh` |
| Data | The Portfolio 4 collections (`vendors`, `products`, `orders`, `reviews`) plus a test database `kasuwa_dist` |

**Security.** The cluster accepts connections only from two IP addresses (`/32` entries: the client server and the student's own machine); `0.0.0.0/0` is not used. The database password was typed into the shell at run time (`read -rs`) and is stored in no file in this repository.

## 2. Evidence files
| File | Shows |
|---|---|
| `ACHEDE_GODWIN_301907619_P5_Topology_Output.txt` | Replica set name, provider/region, all 3 members, role and availability zone of each, `replSetGetStatus` |
| `ACHEDE_GODWIN_301907619_P5_WriteConcern_Output.txt` | Latency of `w:1` against `w:"majority"` against `w:"majority"` + `j:true` |
| `ACHEDE_GODWIN_301907619_P5_ReadPref_Output.txt` | Which node serves reads, and a stale-read test |
| `Atlas_Cluster_Screenshot.png` | Atlas console page of the cluster (add your own screenshot) |
| `01_cluster_topology.js`, `02_write_concern_demo.js`, `03_read_preference_demo.js` | The scripts, runnable with `HOW_TO_RUN.txt` |

## 3. Results

**Replication and availability.** The three members are `00-00` (secondary, `az2`), `00-01` (secondary, `az3`) and `00-02` (primary, `az1`). Writes go to the primary and are replayed by the secondaries. Because each member sits in a different availability zone, the loss of one zone leaves two of three members, which is still a majority, so a new primary can be elected and writes continue.

**Write concern (consistency against latency),** 100 inserts each, measured from the Hetzner client:

| Write concern | Average per write | Meaning |
|---|---|---|
| `w:1` | 8.1 ms | Acknowledged by the primary only |
| `w:"majority"` | 10.2 ms (+26%) | Acknowledged by 2 of 3 nodes, so it survives a primary failure |
| `w:"majority"`, `j:true` | 9.9 ms | As above, and written to the on-disk journal |

The extra ~2 ms is the cost of waiting for a secondary to confirm. (Absolute values also include the network trip between Nuremberg and Frankfurt; the *difference* between rows is what matters.)

**Read preference and consistency.** `readPreference: primary` was served by member `00-02`; `readPreference: secondary` was served by `00-00`, so reads can be spread across members. In the read-your-writes test, 200 documents were each written with `w:1` and read back immediately from a secondary: **5 of 200 reads were stale** (the secondary had not yet received the write). With `w:"majority"` writes and `majority` reads, **0 of 200** were stale. This shows eventual consistency on the fast path and strong consistency when the stronger settings are chosen.

## 4. Discussion: replication, availability, consistency
- **CAP position.** With its defaults MongoDB favours consistency over availability (CP): during a partition, only the side holding a majority keeps accepting writes. Write concern and read concern let the application move toward availability and speed (`w:1`, secondary reads) or toward safety (`majority`) per operation. For payments in this marketplace, `majority` writes are the right choice; for browsing a product catalogue, secondary reads are acceptable.
- **Failover.** If the primary fails, the secondaries hold an election (typically within seconds) and the drivers reconnect automatically. This was **not** demonstrated: the free tier does not let the user trigger a failover. (An Atlas M10+ cluster has a "Test Primary Failover" button.)

## 5. Sharding plan (designed, not deployed)
The free tier cannot shard, so this is a design. If the marketplace outgrew one replica set:
- **`orders`:** shard on a hashed `customer._id`. This spreads writes evenly, and a customer's order history is a targeted query. A shard key on `ordered_at` would be rejected because it is monotonically increasing and sends every new write to one shard.
- **`products`:** shard on `{ category: 1, _id: 1 }`, so category browsing hits few shards.
- **`reviews`:** shard on a hashed `product_id`.
- Small reference data (`vendors`) stays unsharded. A `mongos` router would send queries to the right shards, and each shard would itself be a 3-node replica set.

## 6. Challenges (honest notes)
1. **The first plan did not work.** I tried to install MongoDB directly on the student's Hetzner server. The MongoDB package did not exist for that Ubuntu release, a workaround repository installed, and `mongod` then refused to start because the server's Linux kernel version has a known incompatibility with that MongoDB build. I removed everything (confirming only MongoDB packages were purged), left the production sites untouched, and moved to MongoDB Atlas.
2. **Free-tier limits:** 512 MB storage, shared resources, no failover test, no sharding. The write-latency numbers are small-scale and include network time, so they illustrate the trade-off and are not a benchmark.
3. **Sample size:** 5 stale reads out of 200 is one run; the exact number varies between runs.
