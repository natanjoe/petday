const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

/*===============================
FUNÇÃO: ASSOCIA O PACOTE ADQUIRIDO AO TUTOR
==================================*/
module.exports = onCall(async (request) => {
  const { auth } = request;

  if (!auth) {
    throw new Error("Usuário não autenticado");
  }

  const userId = auth.uid;

  // buscar usuário
  const userSnap = await db
    .collection("usuarios")
    .doc(userId)
    .get();

  if (!userSnap.exists) {
    throw new Error("Usuário não encontrado");
  }

  const userData = userSnap.data();
  const email = userData.email;

  if (!email) {
    throw new Error("Usuário sem email");
  }

  // buscar pacotes pagos ainda não associados
  const pacotesSnap = await db
    .collection("pacotes_adquiridos")
    .where("tutor_id", "==", null)
    .where("email_pagamento", "==", email)
    .where("status", "==", "ativo")
    .get();

  const batch = db.batch();

  pacotesSnap.docs.forEach((doc) => {
    batch.update(doc.ref, {
      tutor_id: userId,
      atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await batch.commit();

  return {
    associados: pacotesSnap.size,
  };
});