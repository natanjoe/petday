const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function seedRacas() {
  const racas = [
    {
      id: "nao_sei",
      data: {
        nome: "Não sei a raça",
        porte: "medio",
        ativo: true,
        editavel_pelo_admin: true,
        criado_em: admin.firestore.FieldValue.serverTimestamp(),
      },
    },
    {
      id: "golden_retriever",
      data: {
        nome: "Golden Retriever",
        porte: "grande",
        ativo: true,
        editavel_pelo_admin: false,
        criado_em: admin.firestore.FieldValue.serverTimestamp(),
      },
    },
    {
      id: "poodle",
      data: {
        nome: "Poodle",
        porte: "medio",
        ativo: true,
        editavel_pelo_admin: false,
        criado_em: admin.firestore.FieldValue.serverTimestamp(),
      },
    },
    {
      id: "chihuahua",
      data: {
        nome: "Chihuahua",
        porte: "pequeno",
        ativo: true,
        editavel_pelo_admin: false,
        criado_em: admin.firestore.FieldValue.serverTimestamp(),
      },
    },
    {
      id: "vira_lata",
      data: {
        nome: "Vira-lata",
        porte: "medio",
        ativo: true,
        editavel_pelo_admin: true,
        criado_em: admin.firestore.FieldValue.serverTimestamp(),
      },
    },
  ];

  for (const raca of racas) {
    await db.collection("racas").doc(raca.id).set(raca.data, {
      merge: true,
    });
    console.log(`✔ Raça criada: ${raca.id}`);
  }

  console.log("✅ Seed de raças finalizado");
  process.exit(0);
}

seedRacas().catch((err) => {
  console.error("❌ Erro ao executar seed:", err);
  process.exit(1);
});
