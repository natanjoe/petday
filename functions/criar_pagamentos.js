const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const db = admin.firestore();

const pagarComMercadoPago = require("./gateways/mercadopago.gateway");

/* ======================================================
   FUNÇÃO: CRIAR PAGAMENTO (ROUTER)
====================================================== */
module.exports = onCall(async (request) => {
  const { data, auth } = request;

  const {
    intencaoCompraId,
    formaPagamento,
    parcelas = 1,
    emailPagamento,
  } = data ?? {};

  if (!intencaoCompraId || !formaPagamento || !emailPagamento) {
    throw new Error("Dados incompletos para pagamento");
  }

  /* ======================================================
     INTENÇÃO DE COMPRA
  ====================================================== */
  const intencaoSnap = await db
    .collection("intencoes_compra")
    .doc(intencaoCompraId)
    .get();

  if (!intencaoSnap.exists) {
    throw new Error("Intenção de compra não encontrada");
  }

  const intencao = intencaoSnap.data();

  if (intencao.status && intencao.status !== "criada") {
    throw new Error("Pagamento já iniciado");
  }

  const crecheId = intencao.creche_id;
  const pacoteId = intencao.pacote_id;
  const preferencias = intencao.preferencias ?? null;

  if (!crecheId || !pacoteId) {
    throw new Error("Intenção inválida");
  }

  /* ======================================================
     GATEWAY ATIVO DA CRECHE
  ====================================================== */
  const gatewaysSnap = await db
    .collection("creches")
    .doc(crecheId)
    .collection("pagamentos")
    .where("ativo", "==", true)
    .limit(1)
    .get();

  if (gatewaysSnap.empty) {
    throw new Error("Nenhum gateway ativo para esta creche");
  }

  const gatewayDoc = gatewaysSnap.docs[0];
  const gatewayId = gatewayDoc.id;
  const gatewayConfig = gatewayDoc.data();

  /* ======================================================
     ROTEADOR
  ====================================================== */
  switch (gatewayId) {
    case "mercadopago":
      return pagarComMercadoPago({
        auth,
        intencaoSnap,
        crecheId,
        pacoteId,
        preferencias,
        formaPagamento,
        parcelas,
        emailPagamento,
        gatewayConfig,
      });

    default:
      throw new Error(`Gateway não suportado: ${gatewayId}`);
  }
});
