const { onCall, onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");
const { MercadoPagoConfig, Payment } = require("mercadopago");

admin.initializeApp();
const db = admin.firestore();

/* ======================================================
   CONFIGURAÇÕES GLOBAIS
====================================================== */
setGlobalOptions({
  region: "us-central1",
  secrets: ["MP_ACCESS_TOKEN"],
});

/* ======================================================
   FUNÇÃO: CRIAR PAGAMENTO
====================================================== */
exports.criarPagamento = onCall(async (request) => {
  const { data, auth } = request;

  const {
    crecheId,
    pacoteId,
    formaPagamento,
    parcelas = 1,
    emailPagamento,

    // 🔑 Preferências vindas do app (ANTES DO PAGAMENTO)
    preferencias, // { raca_id, raca_nome, porte, data_pre_selecionada }
  } = data ?? {};

  if (!crecheId || !pacoteId || !formaPagamento || !emailPagamento) {
    throw new Error("Dados incompletos para pagamento");
  }

  /* ===== GATEWAY ===== */
  const gatewaySnap = await db
    .collection("creches")
    .doc(crecheId)
    .collection("pagamentos")
    .doc("gateway")
    .get();

  if (!gatewaySnap.exists) {
    throw new Error("Gateway não configurado");
  }

  const gatewayConfig = gatewaySnap.data();
  if (!gatewayConfig.ativo) {
    throw new Error("Pagamentos desativados");
  }

  /* ===== PACOTE ===== */
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

  /* ===== VALIDAÇÕES PAGAMENTO ===== */
  if (formaPagamento === "cartao") {
    if (!gatewayConfig.cartao_ativo) {
      throw new Error("Cartão indisponível");
    }
    if (parcelas > gatewayConfig.parcelamento_maximo) {
      throw new Error("Parcelamento inválido");
    }
  }

  if (formaPagamento === "pix" && !gatewayConfig.pix_ativo) {
    throw new Error("PIX indisponível");
  }

  /* ===== VALOR (PADRÃO DEFINITIVO: CENTAVOS) ===== */
  let valorCentavos;

  if (typeof pacote.preco_centavos === "number") {
    valorCentavos = Math.round(pacote.preco_centavos);
  } else if (typeof pacote.preco === "number") {
    valorCentavos = Math.round(pacote.preco * 100);
  } else {
    throw new Error("Preço inválido");
  }

  /* ===== MERCADO PAGO ===== */
  const client = new MercadoPagoConfig({
    accessToken: process.env.MP_ACCESS_TOKEN,
  });

  const payment = new Payment(client);

  const pagamentoMP = await payment.create({
    body: {
      transaction_amount: valorCentavos / 100,
      description: pacote.nome,
      payer: { email: emailPagamento },
      payment_method_id: formaPagamento === "pix" ? "pix" : undefined,
      installments: formaPagamento === "cartao" ? parcelas : undefined,
    },
  });

  /* ===== NORMALIZA PREFERÊNCIAS ===== */
  const preferenciasNormalizadas = preferencias
    ? {
        raca_id: preferencias.raca_id ?? null,
        raca_nome: preferencias.raca_nome ?? null,
        porte: preferencias.porte ?? null,
        data_pre_selecionada: preferencias.data_pre_selecionada ?? null, // yyyy-MM-dd
      }
    : null;

  /* ===== SALVAR PACOTE ADQUIRIDO ===== */
  const pacoteAdquiridoRef = await db.collection("pacotes_adquiridos").add({
    tutor_id: auth?.uid ?? null,
    email_pagamento: emailPagamento,

    creche_id: crecheId,
    pacote_id: pacoteId,
    pacote_nome: pacote.nome,

    // 🔑 Preferências do tutor salvas DEFINITIVAMENTE aqui
    preferencias: preferenciasNormalizadas,

    diarias_totais: pacote.diarias,
    diarias_usadas: 0,

    valor_total_centavos: valorCentavos,

    pagamento: {
      gateway: "mercadopago",
      forma: formaPagamento,
      parcelas,
      external_id: pagamentoMP.id,
      status: pagamentoMP.status,
    },

    status: "pendente_pagamento",

    criado_em: admin.firestore.FieldValue.serverTimestamp(),
    atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    pagamentoId: pagamentoMP.id,
    status: pagamentoMP.status,
    qr_code:
      pagamentoMP.point_of_interaction?.transaction_data?.qr_code ?? null,
    qr_code_base64:
      pagamentoMP.point_of_interaction?.transaction_data?.qr_code_base64 ??
      null,
    pacoteAdquiridoId: pacoteAdquiridoRef.id,
  };
});

/* ======================================================
   WEBHOOK: MERCADO PAGO
====================================================== */
exports.mercadoPagoWebhook = onRequest(async (req, res) => {
  try {
    const { type, data } = req.body;

    if (type !== "payment" || !data?.id) {
      return res.status(200).send("Ignorado");
    }

    const client = new MercadoPagoConfig({
      accessToken: process.env.MP_ACCESS_TOKEN,
    });

    const payment = new Payment(client);
    const pagamento = await payment.get({ id: data.id });

    const snap = await db
      .collection("pacotes_adquiridos")
      .where("pagamento.external_id", "==", pagamento.id)
      .limit(1)
      .get();

    if (snap.empty) {
      return res.status(200).send("Não encontrado");
    }

    const docRef = snap.docs[0].ref;

    let statusFinal = "pendente_pagamento";
    if (pagamento.status === "approved") statusFinal = "ativo";
    if (pagamento.status === "rejected") statusFinal = "cancelado";

    await docRef.update({
      "pagamento.status": pagamento.status,
      status: statusFinal,
      atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.status(200).send("OK");
  } catch (err) {
    console.error(err);
    return res.status(500).send("Erro");
  }
});

/* ======================================================
   FUNÇÃO: CRIAR RESERVA (TUTOR)
====================================================== */
exports.criarReservaTutor = onCall(async (request) => {
  const { auth, data } = request;

  if (!auth) {
    throw new Error("Usuário não autenticado");
  }

  const {
    crecheId,
    dataReserva, // yyyy-MM-dd
    petNome,
    racaId,
    porte,
  } = data ?? {};

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

    tx.update(pacoteDoc.ref, {
      diarias_usadas: admin.firestore.FieldValue.increment(1),
      atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
    });

    tx.set(db.collection("reservas").doc(), {
      tutor_id: auth.uid,
      creche_id: crecheId,
      pacote_adquirido_id: pacoteDoc.id,

      data: dataReserva,
      pet_nome: petNome,
      raca_id: racaId,
      porte,

      status: "confirmada",
      origem: "tutor",

      criado_em: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  return { ok: true };
});
