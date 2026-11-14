// Portfolio 4: MongoDB model for Kasuwa Demo Marketplace (all data invented)
// Run: mongosh --quiet --file 01_seed.js
const kdb = db.getSiblingDB('kasuwa_nosql');
kdb.dropDatabase();

// small deterministic random generator so the data is reproducible
let s = 42;
const rnd  = () => { s = (s * 1664525 + 1013904223) % 4294967296; return s / 4294967296; };
const pick = a => a[Math.floor(rnd() * a.length)];
const int  = (lo, hi) => lo + Math.floor(rnd() * (hi - lo + 1));

const areas = ['Wuse','Garki','Maitama','Asokoro','Gwarinpa','Lugbe','Kubwa','Jabi','Utako','Nyanya'];

// ---- Validation: the document model is flexible, but core fields are still enforced ----
kdb.createCollection('products', { validator: { $jsonSchema: {
  bsonType: 'object',
  required: ['name', 'category', 'price', 'stock', 'vendor'],
  properties: {
    name:     { bsonType: 'string' },
    category: { enum: ['Phones', 'Fashion', 'Groceries', 'Electronics'] },
    price:    { bsonType: ['int', 'long', 'double', 'decimal'], minimum: 1 },
    stock:    { bsonType: ['int', 'long'], minimum: 0 },
    vendor:   { bsonType: 'object', required: ['_id', 'name'] }
  } } } });

// ---- Vendors ----
const vendors = [];
for (let i = 1; i <= 200; i++) vendors.push({ _id: i, name: 'Vendor ' + i, area: pick(areas), status: pick(['active', 'active', 'active', 'pending']) });
kdb.vendors.insertMany(vendors);

// ---- Products: attributes differ per category (this is where a document model fits) ----
const products = [];
for (let i = 1; i <= 5000; i++) {
  const v = pick(vendors), cat = pick(['Phones', 'Fashion', 'Groceries', 'Electronics']);
  let attributes, price;
  if (cat === 'Phones')      { attributes = { brand: pick(['Tecno','Infinix','Samsung','Apple','Xiaomi']), ram_gb: pick([2,4,6,8,12]), storage_gb: pick([32,64,128,256]), battery_mah: int(3000,6000), color: pick(['black','blue','gold']) }; price = int(60000, 900000); }
  else if (cat === 'Fashion'){ attributes = { size: pick(['S','M','L','XL']), color: pick(['red','green','black','white']), material: pick(['cotton','ankara','linen']), gender: pick(['men','women','unisex']) }; price = int(3000, 60000); }
  else if (cat === 'Groceries'){ attributes = { weight_kg: pick([0.5,1,2,5,10]), perishable: rnd() > 0.5, shelf_life_days: int(3, 365) }; price = int(500, 20000); }
  else                       { attributes = { brand: pick(['LG','Hisense','Sony','Philips']), warranty_months: pick([6,12,24]), power_w: int(20, 2000) }; price = int(15000, 600000); }
  products.push({
    _id: i, name: cat + ' item ' + i, category: cat, price: price, stock: int(0, 200), is_active: rnd() > 0.05,
    // embedded snapshot of the vendor: avoids a join on every product page (trade-off: copy can go stale)
    vendor: { _id: v._id, name: v.name, area: v.area },
    attributes: attributes,
    tags: [pick(['new','popular','sale','imported','local']), pick(['gift','everyday','premium'])],
    created_at: new Date(Date.now() - int(0, 700) * 86400000)
  });
}
kdb.products.insertMany(products);

// ---- Orders: one document per order with its items EMBEDDED (items are always read with the order) ----
const orders = [];
for (let i = 1; i <= 3000; i++) {
  const n = int(1, 4), items = [];
  for (let k = 0; k < n; k++) { const p = pick(products); items.push({ product_id: p._id, name: p.name, vendor_id: p.vendor._id, qty: int(1, 3), unit_price: p.price }); }
  const status = pick(['pending','paid','shipped','delivered','delivered','delivered','cancelled']);
  orders.push({
    _id: i, customer: { _id: int(1, 1000), name: 'Customer ' + int(1, 1000), area: pick(areas) },
    status: status, ordered_at: new Date(Date.now() - int(0, 365) * 86400000), delivery_area: pick(areas),
    items: items, total: items.reduce((t, x) => t + x.qty * x.unit_price, 0),
    payment: { method: pick(['card','transfer','ussd']), status: status === 'cancelled' ? 'failed' : (status === 'pending' ? 'pending' : 'success'), reference: 'REF' + String(i).padStart(8, '0') }
  });
}
kdb.orders.insertMany(orders);

// ---- Reviews: REFERENCED (unbounded growth, so not embedded in the product) ----
const reviews = [];
for (let i = 1; i <= 8000; i++) reviews.push({ product_id: int(1, 5000), customer_id: int(1, 1000), rating: int(1, 5), comment: 'Demo review ' + i, created_at: new Date(Date.now() - int(0, 365) * 86400000) });
kdb.reviews.insertMany(reviews);

print('--- Collections and document counts');
['vendors','products','orders','reviews'].forEach(c => print(c.padEnd(10), kdb[c].countDocuments()));
print('--- Sample product (Phones) and sample product (Groceries): different attributes, same collection');
printjson(kdb.products.findOne({ category: 'Phones' }));
printjson(kdb.products.findOne({ category: 'Groceries' }));
print('--- Validation test: inserting a product with negative stock must FAIL');
try { kdb.products.insertOne({ name: 'bad', category: 'Phones', price: 100, stock: -5, vendor: { _id: 1, name: 'x' } }); print('UNEXPECTED: insert succeeded'); }
catch (e) { print('Rejected as expected: ' + (e.codeName || e.code) + ' - ' + e.message.slice(0, 60)); }
