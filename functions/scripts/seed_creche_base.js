const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

/* ======================================================
   SEED: ESTRUTURA BASE DE UMA CRECHE (SaaS)
====================================================== */
module.exports = onCall(async (request) => {
  const { auth, data } = request;

  if (!auth) {
    throw new Error("Usuário não autenticado");
  }

  // 🔐 FUTURO: validar role super-admin
  const { crecheId, nomeCreche, slug } = data ?? {};

  if (!crecheId || !nomeCreche || !slug) {
    throw new Error("crecheId, nomeCreche e slug são obrigatórios");
  }

  const crecheRef = db.collection("creches").doc(crecheId);
  const crecheSnap = await crecheRef.get();

  /* ======================================================
     CRECHE (DOC PRINCIPAL)
  ====================================================== */
  if (!crecheSnap.exists) {
    await crecheRef.set({
      nome_creche: nomeCreche,
      slug,
      ativo: true,

      criado_em: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  /* ======================================================
     PAGAMENTOS — MERCADO PAGO (DEFAULT)
  ====================================================== */
  const mpRef = crecheRef.collection("pagamentos").doc("mercadopago");
  const mpSnap = await mpRef.get();

  if (!mpSnap.exists) {
    await mpRef.set({
      ativo: false,

      pix_ativo: false,
      cartao_ativo: false,
      parcelamento_maximo: 1,

      // 🔑 apenas o NOME do secret
      secret_name: null,

      ambiente: "producao",

      criado_em: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  /* ======================================================
     PAGAMENTOS — PLACEHOLDER OUTROS GATEWAYS
  ====================================================== */
  const outrosGateways = ["stripe", "paypal"];

  for (const gatewayId of outrosGateways) {
    const ref = crecheRef.collection("pagamentos").doc(gatewayId);
    const snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        ativo: false,
        criado_em: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  }

  /* ======================================================
     AGENDA DIÁRIA (ESTRUTURA BASE)
  ====================================================== */
  const agendaBaseRef = crecheRef
    .collection("agenda_diaria")
    .doc("_config");

  const agendaBaseSnap = await agendaBaseRef.get();

  if (!agendaBaseSnap.exists) {
    await agendaBaseRef.set({
      limite_padrao: {
        pequeno: 10,
        medio: 8,
        grande: 5,
      },
      criado_em: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  /* ======================================================
     PACOTES EXEMPLO
  ====================================================== */
  const pacotesRef = crecheRef.collection("pacotes");
  const pacotesSnap = await pacotesRef.limit(1).get();

  if (pacotesSnap.empty) {
    await pacotesRef.add({
      nome: "Pacote Inicial",
      descricao: "Pacote promocional de boas-vindas",
      diarias: 5,
      preco_centavos: 5000, // R$ 50,00
      ativo: false,
      criado_em: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return {
    ok: true,
    message: "Seed da creche aplicado com sucesso",
  };
});
