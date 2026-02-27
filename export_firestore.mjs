import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { readFileSync, writeFileSync } from 'fs';

const serviceAccount = JSON.parse(readFileSync('./coentrepreneurs-7b291-firebase-adminsdk-fbsvc-59df3661c4.json', 'utf8'));

initializeApp({ credential: cert(serviceAccount) });
const db = getFirestore();

async function exportAll() {
  const collections = await db.listCollections();
  const result = {};

  for (const col of collections) {
    console.log(`Exportation de la collection : ${col.id}`);
    const snapshot = await col.get();
    result[col.id] = {};
    for (const doc of snapshot.docs) {
      result[col.id][doc.id] = doc.data();
    }
  }

  writeFileSync('backup.json', JSON.stringify(result, null, 2), 'utf8');
  console.log(`\nExport terminé → backup.json (${Object.keys(result).length} collections)`);
}

exportAll().catch(console.error);
