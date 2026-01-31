const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
});

const db = admin.firestore();

async function inspect() {
  const collections = await db.listCollections();

  for (const col of collections) {
    console.log(`\n📁 Coleção: ${col.id}`);

    const snap = await col.limit(3).get(); // limita pra não explodir custo
    snap.docs.forEach(doc => {
      console.log(`  📄 Doc: ${doc.id}`);
      console.log(`     Campos:`, Object.keys(doc.data()));
    });
  }
}

inspect();
