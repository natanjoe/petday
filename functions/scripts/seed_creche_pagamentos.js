const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

/* ======================================================
   SEED: CONFIGURA PAGAMENTOS DA CRECHE
   (MERCADO PAGO)
====================================================== */
module.exports = onCall(async (request) => {
  const { auth, data } = request;

  if (!auth) {
    throw new Error("Usuário não autenticado");
  }

  // 🔐 aqui futuramente você pode validar role admin
  const { crecheId } = data ?? {};

  if (!crecheId) {
    throw new Error("crecheId é obrigatório");
  }

  const crecheRef = db.collection("creches").doc(crecheId);
  const crecheSnap = await crecheRef.get();

  if (!crecheSnap.exists) {
    throw new Error("Creche não encontrada");
  }

  const pagamentoRef = crecheRef
    .collection("pagamentos")
    .doc("mercadopago");

  const pagamentoSnap = await pagamentoRef.get();

  if (pagamentoSnap.exists) {
    return {
      ok: true,
      message: "Pagamentos já configurados",
    };
  }

  await pagamentoRef.set({
    ativo: false,
    pix_ativo: false,
    cartao_ativo: false,

    // 🔑 nome do secret (será preenchido depois)
    secret_name: null,

    ambiente: "producao",

    criado_em: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    ok: true,
    message: "Configuração de pagamentos criada",
  };
});
