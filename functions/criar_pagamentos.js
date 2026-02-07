const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const express = require("express");
const cors = require("cors");

const pagarComMercadoPago = require("./gateways/mercadopago.gateway");

const db = admin.firestore();

/* ======================================================
   APP EXPRESS
====================================================== */
const app = express();

// CORS liberado (ajustar depois se quiser)
app.use(cors({ origin: true }));

// 🔴 ESSENCIAL — parse do JSON
app.use(express.json());

/* ======================================================
   ROTA: CRIAR PAGAMENTO
====================================================== */
app.post("/", async (req, res) => {
  try {
    const {
      intencaoCompraId,
      formaPagamento,
      parcelas = 1,
      emailPagamento,
    } = req.body ?? {};

    if (!intencaoCompraId || !formaPagamento || !emailPagamento) {
      return res.status(400).json({
        error: "Dados incompletos para pagamento",
      });
    }

    /* ======================================================
       INTENÇÃO DE COMPRA
    ====================================================== */
    const intencaoSnap = await db
      .collection("intencoes_compra")
      .doc(intencaoCompraId)
      .get();

    if (!intencaoSnap.exists) {
      return res.status(404).json({
        error: "Intenção de compra não encontrada",
      });
    }

    const intencao = intencaoSnap.data();

    if (intencao.status && intencao.status !== "criada") {
      return res.status(409).json({
        error: "Pagamento já iniciado",
      });
    }

    const crecheId = intencao.creche_id;
    const pacoteId = intencao.pacote_id;
    const preferencias = intencao.preferencias ?? null;

    if (!crecheId || !pacoteId) {
      return res.status(400).json({
        error: "Intenção inválida",
      });
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
      return res.status(400).json({
        error: "Nenhum gateway ativo para esta creche",
      });
    }

    const gatewayDoc = gatewaysSnap.docs[0];
    const gatewayId = gatewayDoc.id;
    const gatewayConfig = gatewayDoc.data();

    /* ======================================================
       RESOLVE ACCESS TOKEN (SECRET)
    ====================================================== */
    const secretName = gatewayConfig.secret_name;
    const accessToken = process.env[secretName];

    if (!accessToken) {
      console.error("Secret não encontrada:", secretName);
      return res.status(500).json({
        error: "Configuração de pagamento inválida",
      });
    }

    /* ======================================================
       ROTEADOR DE GATEWAY
    ====================================================== */
    let resultado;

    switch (gatewayId) {
      case "mercadopago":
        resultado = await pagarComMercadoPago({
          auth: null, // pagamento público
          intencaoSnap,
          crecheId,
          pacoteId,
          preferencias,
          formaPagamento,
          parcelas,
          emailPagamento,
          accessToken,
        });
        break;

      default:
        return res.status(400).json({
          error: `Gateway não suportado: ${gatewayId}`,
        });
    }

    /* ======================================================
       SUCESSO
    ====================================================== */
    return res.status(200).json(resultado);
  } catch (err) {
    console.error("Erro ao criar pagamento:", err);

    return res.status(500).json({
      error: "Erro ao processar pagamento",
    });
  }
});

/* ======================================================
   EXPORT
====================================================== */
module.exports = onRequest(
  {
    region: "us-central1",
  },
  app
);
