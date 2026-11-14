// Run: mongosh --quiet --file 03_indexes.js
const kdb = db.getSiblingDB('kasuwa_nosql');
function plan(label, cursor) {
  const e = cursor.explain('executionStats').executionStats;
  const stage = JSON.stringify(cursor.explain('queryPlanner').queryPlanner.winningPlan).match(/"stage":"(COLLSCAN|IXSCAN)"/);
  print(label.padEnd(34), 'stage=' + (stage ? stage[1] : '?'), ' docsExamined=' + e.totalDocsExamined, ' returned=' + e.nReturned, ' ms=' + e.executionTimeMillis);
}
const qPhones  = () => kdb.products.find({ category: 'Phones', 'attributes.ram_gb': { $gte: 8 }, price: { $lt: 300000 } }).sort({ price: 1 });
const qCustomer= () => kdb.orders.find({ 'customer._id': 77 }).sort({ ordered_at: -1 });
const qSearch  = () => kdb.products.find({ $text: { $search: '"Phones item 4242"' } });

kdb.products.dropIndexes(); kdb.orders.dropIndexes();
print('--- BEFORE indexes');
plan('Phones filter + sort by price', qPhones());
plan('Orders of customer 77, newest first', qCustomer());

print('--- Creating indexes');
printjson(kdb.products.createIndex({ category: 1, price: 1 }));                       // equality + sort
printjson(kdb.products.createIndex({ category: 1, 'attributes.ram_gb': 1 }));           // flexible attribute
printjson(kdb.orders.createIndex({ 'customer._id': 1, ordered_at: -1 }));               // filter + sort
printjson(kdb.products.createIndex({ name: 'text' }));                                  // text search

print('--- AFTER indexes');
plan('Phones filter + sort by price', qPhones());
plan('Orders of customer 77, newest first', qCustomer());
print('Text search "Phones item 4242" returns', qSearch().itcount(), 'documents');
print('--- Index list on products');
kdb.products.getIndexes().forEach(i => print(' ', i.name));
