const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

/* ======================================================
   FUNÇÃO: CRIAR RESERVA (TUTOR)
====================================================== */
module.exports  = onCall(async (request) => {
  const { auth, data } = request;

  if (!auth) {
    throw new Error("Usuário não autenticado");
  }

  const { crecheId, dataReserva, petNome, racaId, porte } = data ?? {};

  if (!crecheId || !dataReserva || !petNome || !racaId || !porte) {
    throw new Error("Dados incompletos");
  }

  await db.runTransaction(async (tx) => {
    const pacoteQuery = db
      .collection("pacotes_adquiridos")
      .where("tutor_id", "==", auth.uid)
      .where("status", "==", "ativo")
      .limit(1);

    const pacoteSnap = await tx.get(pacoteQuery);

    if (pacoteSnap.empty) {
      throw new Error("Nenhum pacote ativo");
    }

    const pacoteDoc = pacoteSnap.docs[0];
    const pacote = pacoteDoc.data();

    if (pacote.diarias_usadas >= pacote.diarias_totais) {
      throw new Error("Sem diárias disponíveis");
    }

    // Agenda
    const agendaRef = db
      .collection("creches")
      .doc(crecheId)
      .collection("agenda_diaria")
      .doc(dataReserva);

    const agendaSnap = await tx.get(agendaRef);
    const agenda = agendaSnap.exists ? agendaSnap.data() : {};

    const ocupadas = agenda?.ocupadas?.[porte] ?? 0;
    const limite = agenda?.limite?.[porte] ?? 0;

    if (limite && ocupadas >= limite) {
      throw new Error("Dia lotado");
    }

    tx.set(
      agendaRef,
      {
        ocupadas: {
          ...(agenda?.ocupadas ?? {}),
          [porte]: ocupadas + 1,
        },
      },
      { merge: true }
    );

    tx.set(db.collection("reservas").doc(), {
      tutor_id: auth.uid,
      creche_id: crecheId,
      pacote_adquirido_id: pacoteDoc.id,

      data: dataReserva,
      pet_nome: petNome,
      raca_id: racaId,
      porte,

      status: "reservada",
      checkin: false,

      criado_em: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true };
});