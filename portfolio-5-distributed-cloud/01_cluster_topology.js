// Portfolio 5: deployment evidence for the Atlas replica set (AWS eu-central-1)
// Run: ATLAS_USER=<user> ATLAS_PW=<pw> mongosh "mongodb+srv://<cluster>/" -u $ATLAS_USER -p "$ATLAS_PW" --quiet --file 01_cluster_topology.js
const h = db.hello();
print('Replica set name :', h.setName);
print('Provider/region  :', h.tags && h.tags.provider, '/', h.tags && h.tags.region);
print('Members (', h.hosts.length, '):'); h.hosts.forEach(x => print('   ', x));
print('Current primary  :', h.primary);
print('Connected to     :', h.me, '(writable primary =', h.isWritablePrimary + ')');
print('--- Role, availability zone and node type of EACH member (direct connection to every host)');
const user = process.env.ATLAS_USER, pw = process.env.ATLAS_PW;
h.hosts.forEach(host => {
  try {
    const c = new Mongo('mongodb://' + encodeURIComponent(user) + ':' + encodeURIComponent(pw) + '@' + host + '/?tls=true&authSource=admin&directConnection=true');
    const x = c.getDB('admin').runCommand({ hello: 1 });
    print(host.split('.')[0].padEnd(26), x.isWritablePrimary ? 'PRIMARY  ' : 'SECONDARY', ' zone=' + (x.tags && x.tags.availabilityZone), ' type=' + (x.tags && x.tags.nodeType));
  } catch (e) { print(host.split('.')[0].padEnd(26), 'could not connect directly:', e.message.slice(0, 80)); }
});
print('--- replSetGetStatus (may be restricted on the free tier)');
try { db.adminCommand({ replSetGetStatus: 1 }).members.forEach(m => print('   ', m.name, m.stateStr)); }
catch (e) { print('   Not permitted on this tier:', e.codeName || e.message.slice(0, 80)); }
