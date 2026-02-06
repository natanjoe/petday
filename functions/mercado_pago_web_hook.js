const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { MercadoPagoConfig, Payment } = require("mercadopago");

const db = admin.firestore();

/* ======================================================
   WEBHOOK: MERCADO PAGO (MULTI-CRECHE / SAAS)
====================================================== */
module.exports = onRequest(async (req, res) => {
  try {
    const { type, data } = req.body;

    // Ignora eventos que não sejam pagamento
    if (type !== "payment" || !data?.id) {
      return res.status(200).send("Ignorado");
    }

    const paymentId = data.id;

    /* ======================================================
       LOCALIZA O PACOTE ADQUIRIDO
    ====================================================== */
    const snap = await db
      .collection("pacotes_adquiridos")
      .where("pagamento.external_id", "==", paymentId)
      .limit(1)
      .get();

    if (snap.empty) {
      // Webhook pode chegar antes da gravação
      console.warn("Pagamento não encontrado:", paymentId);
      return res.status(200).send("Não encontrado");
    }

    const pacoteDoc = snap.docs[0];
    const pacoteData = pacoteDoc.data();
    const crecheId = pacoteData.creche_id;

    if (!crecheId) {
      throw new Error("Pacote sem creche associada");
    }

    /* ======================================================
       CONFIGURAÇÃO DO MERCADO PAGO DA CRECHE
    ====================================================== */
    const gatewaySnap = await db
      .collection("creches")
      .doc(crecheId)
      .collection("pagamentos")
      .doc("mercadopago")
      .get();

    if (!gatewaySnap.exists || !gatewaySnap.data()?.ativo) {
      throw new Error("Gateway Mercado Pago inativo para a creche");
    }

    const gatewayConfig = gatewaySnap.data();
    const secretName = gatewayConfig.secret_name;
    const accessToken = process.env[secretName];

    if (!accessToken) {
      throw new Error(
        `Secret não configurado para a creche (${secretName})`
      );
    }

    /* ======================================================
       CONSULTA O PAGAMENTO NO MP CORRETO
    ====================================================== */
    const client = new MercadoPagoConfig({
      accessToken,
      options: { timeout: 5000 },
    });

    const payment = new Payment(client);
    const pagamento = await payment.get({ id: paymentId });

    /* ======================================================
       STATUS FINAL
    ====================================================== */
    let statusFinal = "pendente_pagamento";

    if (pagamento.status === "approved") statusFinal = "ativo";
    if (pagamento.status === "rejected") statusFinal = "cancelado";

    /* ======================================================
       ATUALIZA PACOTE
    ====================================================== */
    await pacoteDoc.ref.update({
      "pagamento.status": pagamento.status,
      status: statusFinal,
      atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(200).send("OK");
  } catch (err) {
    console.error("Erro webhook Mercado Pago:", err);
    return res.status(500).send("Erro");
  }
});
