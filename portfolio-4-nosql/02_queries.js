// Run: mongosh --quiet --file 02_queries.js
const kdb = db.getSiblingDB('kasuwa_nosql');

print('=== Q1: Phones with >= 8GB RAM and >= 128GB storage under 300,000, cheapest 5 (querying flexible attributes)');
kdb.products.find({ category: 'Phones', 'attributes.ram_gb': { $gte: 8 }, 'attributes.storage_gb': { $gte: 128 }, price: { $lt: 300000 }, is_active: true },
                  { name: 1, price: 1, 'attributes.ram_gb': 1, 'attributes.storage_gb': 1 }).sort({ price: 1 }).limit(5).forEach(printjson);

print('=== Q2: Products tagged "sale" in Groceries that are perishable (array + nested field)');
print('count =', kdb.products.countDocuments({ tags: 'sale', category: 'Groceries', 'attributes.perishable': true }));

print('=== Q3: Top 5 vendors by revenue from DELIVERED orders (aggregation pipeline: $match, $unwind, $group, $sort, $limit)');
kdb.orders.aggregate([
  { $match: { status: 'delivered' } },
  { $unwind: '$items' },
  { $group: { _id: '$items.vendor_id', revenue: { $sum: { $multiply: ['$items.qty', '$items.unit_price'] } }, units: { $sum: '$items.qty' } } },
  { $sort: { revenue: -1 } }, { $limit: 5 }
]).forEach(printjson);

print('=== Q4: Sales per delivery area and month, last 3 months with data ($group on date parts)');
kdb.orders.aggregate([
  { $match: { status: { $in: ['paid', 'shipped', 'delivered'] } } },
  { $group: { _id: { area: '$delivery_area', month: { $dateToString: { format: '%Y-%m', date: '$ordered_at' } } }, orders: { $sum: 1 }, sales: { $sum: '$total' } } },
  { $sort: { '_id.month': -1, sales: -1 } }, { $limit: 6 }
]).forEach(printjson);

print('=== Q5: Average rating of the 5 best-reviewed products with >= 3 reviews ($group on reviews + $lookup to products)');
kdb.reviews.aggregate([
  { $group: { _id: '$product_id', avg_rating: { $avg: '$rating' }, n: { $sum: 1 } } },
  { $match: { n: { $gte: 3 } } }, { $sort: { avg_rating: -1, n: -1 } }, { $limit: 5 },
  { $lookup: { from: 'products', localField: '_id', foreignField: '_id', as: 'p' } },
  { $project: { _id: 1, avg_rating: { $round: ['$avg_rating', 2] }, n: 1, name: { $first: '$p.name' } } }
]).forEach(printjson);

print('=== Q6: Atomic stock decrement on ONE document (single-document operations are atomic in MongoDB)');
kdb.products.updateOne({ _id: 10 }, { $set: { stock: 5 } });
let r1 = kdb.products.updateOne({ _id: 10, stock: { $gte: 3 } }, { $inc: { stock: -3 } });
print('buy 3 of 5 -> modifiedCount =', r1.modifiedCount, ', stock now', kdb.products.findOne({ _id: 10 }).stock);
let r2 = kdb.products.updateOne({ _id: 10, stock: { $gte: 3 } }, { $inc: { stock: -3 } });
print('buy 3 of 2 -> modifiedCount =', r2.modifiedCount, '(refused: condition and update happen atomically, no oversell)');

print('=== Q7: Update one element inside an embedded array (arrayFilters)');
kdb.orders.updateOne({ _id: 1 }, { $set: { 'items.$[i].qty': 9 } }, { arrayFilters: [{ 'i.product_id': kdb.orders.findOne({ _id: 1 }).items[0].product_id }] });
printjson(kdb.orders.findOne({ _id: 1 }, { items: 1 }));
