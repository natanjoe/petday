const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

/*======================================================
FUNÇÃO:A CRECHE FAZ O CHECK-IN DO ANIMAL
=======================================================*/
module.exports = onCall(async (request) => {
  const { auth, data } = request;

  if (!auth) {
    throw new Error("Usuário não autenticado");
  }

  const { reservaId } = data ?? {};
  if (!reservaId) {
    throw new Error("Reserva inválida");
  }

  await db.runTransaction(async (tx) => {
    const reservaRef = db.collection("reservas").doc(reservaId);
    const reservaSnap = await tx.get(reservaRef);

    if (!reservaSnap.exists) {
      throw new Error("Reserva não encontrada");
    }

    const reserva = reservaSnap.data();

    if (reserva.checkin === true) {
      throw new Error("Reserva já teve check-in");
    }

    const pacoteRef = db
      .collection("pacotes_adquiridos")
      .doc(reserva.pacote_adquirido_id);

    const pacoteSnap = await tx.get(pacoteRef);
    const pacote = pacoteSnap.data();

    if (pacote.diarias_usadas >= pacote.diarias_totais) {
      throw new Error("Pacote sem saldo");
    }

    // ✔️ Marca check-in
    tx.update(reservaRef, {
      checkin: true,
      status: "confirmada",
      checkin_em: admin.firestore.FieldValue.serverTimestamp(),
    });

    // ✔️ Consome diária
    tx.update(pacoteRef, {
      diarias_usadas: admin.firestore.FieldValue.increment(1),
      atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true };
});