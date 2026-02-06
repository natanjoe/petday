const admin = require("firebase-admin");
const { MercadoPagoConfig, Payment } = require("mercadopago");

const db = admin.firestore();

/* ======================================================
   GATEWAY: MERCADO PAGO
====================================================== */
module.exports = async function pagarComMercadoPago({
  auth,
  intencaoSnap,
  crecheId,
  pacoteId,
  preferencias,
  formaPagamento,
  parcelas,
  emailPagamento,
  accessToken, // 👈 vem VALIDADO do router
}) {
  /* ===============================
     PACOTE
  =============================== */
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

  if (typeof pacote.preco_centavos !== "number") {
    throw new Error("Preço inválido no pacote");
  }

  const valorCentavos = Math.round(pacote.preco_centavos);

  /* ===============================
     MERCADO PAGO – CRIAR PAGAMENTO
  =============================== */
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
      payer: { email: emailPagamento },
    },
  });

  /* ===============================
     PACOTE ADQUIRIDO
  =============================== */
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

  /* ===============================
     ATUALIZA INTENÇÃO
  =============================== */
  await intencaoSnap.ref.update({
    status: "pagamento_criado",
    pacote_adquirido_id: pacoteAdquiridoRef.id,
    atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
  });

  /* ===============================
     RETORNO
  =============================== */
  return {
    pagamentoId: pagamentoMP.id,
    status: pagamentoMP.status,
    pix_qr_code_base64:
      pagamentoMP.point_of_interaction?.transaction_data?.qr_code_base64 ?? null,
    pix_copia_e_cola:
      pagamentoMP.point_of_interaction?.transaction_data?.qr_code ?? null,
    pacoteAdquiridoId: pacoteAdquiridoRef.id,
  };
};
