// Run: mongosh "<uri>" -u ... -p ... --quiet --file 03_read_preference_demo.js
const k = db.getSiblingDB('kasuwa_dist');
if (k.orders.countDocuments() === 0) { print('Run 02_write_concern_demo.js first.'); quit(1); }
const host = c => c.explain().serverInfo.host.split('.')[0];
print('--- Which node answers a read?');
print('readPreference primary   ->', host(k.orders.find({ i: 1 }).readPref('primary')));
print('readPreference secondary ->', host(k.orders.find({ i: 1 }).readPref('secondary')));
print('--- Read-your-writes test: write with w:1 to the primary, then IMMEDIATELY read from a secondary (200 rounds)');
let stale = 0;
for (let n = 0; n < 200; n++) {
  const id = 'rw-' + n;
  k.orders.insertOne({ _id: id, total: n }, { writeConcern: { w: 1 } });
  if (k.orders.find({ _id: id }).readPref('secondary').toArray().length === 0) stale++;
}
print('Stale reads with w:1 + secondary read           :', stale, 'of 200');
stale = 0;
for (let n = 0; n < 200; n++) {
  const id = 'rm-' + n;
  k.orders.insertOne({ _id: id, total: n }, { writeConcern: { w: 'majority' } });
  if (k.orders.find({ _id: id }).readPref('secondary').readConcern('majority').toArray().length === 0) stale++;
}
print('Stale reads with w:majority + majority read     :', stale, 'of 200  (majority write + majority read is the strong-consistency setting)');
print('(A non-zero count in the first line shows eventual consistency; zero means replication lag was below the read delay on this run.)');
