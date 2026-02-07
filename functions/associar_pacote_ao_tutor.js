const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

/*===============================
FUNÇÃO: ASSOCIA O PACOTE ADQUIRIDO AO TUTOR
- idempotente
- segura
- NÃO quebra pagamento
==================================*/
module.exports = onCall(async (request) => {
  const { auth } = request;

  // 🔐 Sem auth? Não faz nada, mas NÃO quebra o fluxo
  if (!auth) {
    return { associados: 0 };
  }

  const userId = auth.uid;

  // buscar usuário
  const userSnap = await db
    .collection("usuarios")
    .doc(userId)
    .get();

  if (!userSnap.exists) {
    // aqui é erro real
    throw new HttpsError("not-found", "Usuário não encontrado");
  }

  const userData = userSnap.data();
  const email = userData.email;

  if (!email) {
    throw new HttpsError(
      "failed-precondition",
      "Usuário não possui email"
    );
  }

  // buscar pacotes pagos ainda não associados
  const pacotesSnap = await db
    .collection("pacotes_adquiridos")
    .where("tutor_id", "==", null)
    .where("email_pagamento", "==", email)
    .where("status", "==", "ativo")
    .get();

  if (pacotesSnap.empty) {
    return { associados: 0 };
  }

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
