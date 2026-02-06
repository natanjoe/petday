const { onCall } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { MercadoPagoConfig, Payment } = require("mercadopago");

const db = admin.firestore();

/* ======================================================
   FUNÇÃO: CRIAR PAGAMENTO (SaaS / Multi-creche)
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
     INTENÇÃO DE COMPRA (FONTE DA VERDADE)
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
    throw new Error("Pagamento já iniciado para esta intenção");
  }

  const crecheId = intencao.creche_id;
  const pacoteId = intencao.pacote_id;
  const preferencias = intencao.preferencias ?? null;

  if (!crecheId || !pacoteId) {
    throw new Error("Intenção inválida");
  }

  /* ======================================================
     CONFIGURAÇÃO DO GATEWAY (CRECHE)
  ====================================================== */
  const gatewaySnap = await db
    .collection("creches")
    .doc(crecheId)
    .collection("pagamentos")
    .doc("mercadopago")
    .get();

  if (!gatewaySnap.exists || !gatewaySnap.data()?.ativo) {
    throw new Error("Pagamentos indisponíveis para esta creche");
  }

  const gatewayConfig = gatewaySnap.data();

  if (formaPagamento === "pix" && !gatewayConfig.pix_ativo) {
    throw new Error("PIX indisponível");
  }

  if (formaPagamento === "cartao") {
    if (!gatewayConfig.cartao_ativo) {
      throw new Error("Cartão indisponível");
    }
    if (parcelas > gatewayConfig.parcelamento_maximo) {
      throw new Error("Parcelamento inválido");
    }
  }

  /* ======================================================
     TOKEN DO MERCADO PAGO (SECRET)
  ====================================================== */
  const secretName = gatewayConfig.secret_name;
  const accessToken = process.env[secretName];

  if (!accessToken) {
    throw new Error("Token do Mercado Pago não configurado para esta creche");
  }

  /* ======================================================
     PACOTE
  ====================================================== */
  const pacoteSnap = await db
    .collection("creches")
    .doc(crecheId)
    .collection("pacotes")
    .doc(pacoteId)
    .get();

  if (!pacoteSnap.exists) {
    throw new Error("Pacote não encontrado");
  }

  const pacote = pacoteSnap.data();
  if (!pacote.ativo) {
    throw new Error("Pacote indisponível");
  }

  /* ======================================================
     VALOR (CENTAVOS – SEMPRE)
  ====================================================== */
  if (typeof pacote.preco_centavos !== "number") {
    throw new Error("Preço inválido no pacote");
  }

  const valorCentavos = Math.round(pacote.preco_centavos);

  /* ======================================================
     MERCADO PAGO — CRIAÇÃO DO PAGAMENTO
  ====================================================== */
  const client = new MercadoPagoConfig({
    accessToken,
    options: { timeout: 5000 },
  });

  const payment = new Payment(client);

  const pagamentoMP = await payment.create({
    body: {
      transaction_amount: valorCentavos / 100,
      description: `Pacote ${pacote.nome}`,
      payment_method_id: formaPagamento === "pix" ? "pix" : undefined,
      installments: formaPagamento === "cartao" ? parcelas : undefined,
      payer: {
        email: emailPagamento,
      },
    },
  });

  /* ======================================================
     PACOTE ADQUIRIDO
  ====================================================== */
  const pacoteAdquiridoRef = await db.collection("pacotes_adquiridos").add({
    tutor_id: auth?.uid ?? null,
    email_pagamento: emailPagamento,

    creche_id: crecheId,
    pacote_id: pacoteId,
    pacote_nome: pacote.nome,

    preferencias,

    diarias_totais: pacote.diarias,
    diarias_usadas: 0,

    valor_total_centavos: valorCentavos,

    pagamento: {
      gateway: "mercadopago",
      metodo: formaPagamento,
      parcelas,
      external_id: pagamentoMP.id,
      status: pagamentoMP.status,
    },

    status: "pendente_pagamento",

    criado_em: admin.firestore.FieldValue.serverTimestamp(),
    atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
  });

  /* ======================================================
     MARCAR INTENÇÃO
  ====================================================== */
  await intencaoSnap.ref.update({
    status: "pagamento_criado",
    pacote_adquirido_id: pacoteAdquiridoRef.id,
    atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
  });

  /* ======================================================
     RETORNO PARA O CLIENTE
  ====================================================== */
  return {
    pagamentoId: pagamentoMP.id,
    status: pagamentoMP.status,

    pix_qr_code_base64:
      pagamentoMP.point_of_interaction?.transaction_data?.qr_code_base64 ?? null,

    pix_copia_e_cola:
      pagamentoMP.point_of_interaction?.transaction_data?.qr_code ?? null,

    pacoteAdquiridoId: pacoteAdquiridoRef.id,
  };
});
