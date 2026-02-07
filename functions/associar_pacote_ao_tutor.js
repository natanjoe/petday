const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

module.exports = onCall(
  { region: "us-central1", enforceAppCheck: false },
  async (request) => {
    const { auth } = request;

    if (!auth?.uid || !auth?.token?.email) {
      return { associados: 0 };
    }

    const userId = auth.uid;
    const email = auth.token.email;

    const snap = await db
      .collection("pacotes_adquiridos")
      .where("tutor_id", "==", null)
      .where("email_pagamento", "==", email)
      .where("status", "==", "ativo")
      .get();

    if (snap.empty) return { associados: 0 };

    const batch = db.batch();

    snap.docs.forEach((doc) => {
      batch.update(doc.ref, {
        tutor_id: userId,
        atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();

    return { associados: snap.size };
  }
);
