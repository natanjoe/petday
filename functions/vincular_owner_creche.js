const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

module.exports = onCall(
  {
    region: "us-central1",
    enforceAppCheck: false, // 🔴 ESSENCIAL  
  },
  async (request) => {
  const { auth } = request;

  if (!auth || !auth.token.email) {
    throw new Error("Usuário não autenticado");
  }

  const email = auth.token.email.toLowerCase();

  // 🔍 procura creche cujo owner_email == email
  const crechesSnap = await db
    .collection("creches")
    .where("owner_email", "==", email)
    .limit(1)
    .get();

  if (crechesSnap.empty) {
    return { ok: false, message: "Usuário não é owner de nenhuma creche" };
  }

  const crecheDoc = crechesSnap.docs[0];
  const crecheId = crecheDoc.id;

  const adminRef = db
    .collection("creches")
    .doc(crecheId)
    .collection("admins")
    .doc(auth.uid);

  const adminSnap = await adminRef.get();

  if (!adminSnap.exists) {
    await adminRef.set({
      email,
      role: "owner",
      ativo: true,
      criado_em: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return {
    ok: true,
    crecheId,
    role: "owner",
  };
});