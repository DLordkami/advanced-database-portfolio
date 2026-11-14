// Run: mongosh "<uri>" -u ... -p ... --quiet --file 02_write_concern_demo.js
const k = db.getSiblingDB('kasuwa_dist');
k.dropDatabase();
function bench(label, wc, n) {
  const t0 = Date.now();
  for (let i = 0; i < n; i++) k.orders.insertOne({ batch: label, i: i, total: 1000 + i, status: 'paid' }, { writeConcern: wc });
  const ms = Date.now() - t0;
  print(label.padEnd(34), n + ' inserts in ' + ms + ' ms  ->  avg ' + (ms / n).toFixed(1) + ' ms per write');
}
print('--- Write concern vs latency (each write waits for a different level of acknowledgement)');
bench('w:1  (primary only)', { w: 1 }, 100);
bench('w:"majority" (2 of 3 nodes)', { w: 'majority' }, 100);
bench('w:"majority", j:true (journaled)', { w: 'majority', j: true }, 100);
print('Total documents written:', k.orders.countDocuments());
print('--- Trade-off: w:1 is fastest but a primary crash before replication could lose the write;');
print('    w:"majority" survives a primary failure (a majority already has it) at the cost of latency.');
