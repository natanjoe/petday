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
    intencaoCompraId,
    formaPagamento,
    parcelas = 1,
    emailPagamento,
  } = data ?? {};

  if (!intencaoCompraId || !formaPagamento || !emailPagamento) {
    throw new Error("Dados incompletos para pagamento");
  }

  /*
   *BUSCAR INTENÇÃO DE COMPRA (FONTE DA VERDADE)
   */
  const intencaoSnap = await db
    .collection("intencoes_compra")
    .doc(intencaoCompraId)
    .get();

  if (!intencaoSnap.exists) {
    throw new Error("Intenção de compra não encontrada");
  }

  const intencao = intencaoSnap.data();

  const crecheId = intencao.creche_id;
  const pacoteId = intencao.pacote_id;
  const preferencias = intencao.preferencias ?? null;

  if (!crecheId || !pacoteId) {
    throw new Error("Intenção inválida");
  }

  /*
   *  GATEWAY
   */
/*  const gatewaySnap = await db
    .collection("creches")
    .doc(crecheId)
    .collection("pagamentos")
    .doc("gateway")
    .get();

  if (!gatewaySnap.exists || !gatewaySnap.data()?.ativo) {
    throw new Error("Pagamentos indisponíveis");
  }

  const gatewayConfig = gatewaySnap.data();
*/
    //gatway temporario
    let gatewayConfig = {
      pix_ativo: true,
      cartao_ativo: false,
      parcelamento_maximo: 1,
    };

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
     VALIDAÇÕES PAGAMENTO
  ====================================================== */
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

  /* ======================================================
     VALOR (CENTAVOS)
  ====================================================== */
  let valorCentavos;

  if (typeof pacote.preco_centavos === "number") {
    valorCentavos = Math.round(pacote.preco_centavos);
  } else if (typeof pacote.preco === "number") {
    valorCentavos = Math.round(pacote.preco * 100);
  } else {
    throw new Error("Preço inválido");
  }

  /* ======================================================
   MERCADO PAGO
  ====================================================== */
  /*
    const client = new MercadoPagoConfig({
      accessToken: process.env.MP_ACCESS_TOKEN,
    });

    const payment = new Payment(client);

    const paymentData = {
      transaction_amount: valorCentavos / 100, // número decimal
      description: `Pacote ${pacote.nome}`,
      payment_method_id: "pix",
      payer: {
        email: emailPagamento,
      },
    };

    console.log("MP TOKEN PREFIX:", process.env.MP_ACCESS_TOKEN.slice(0, 5));
    console.log("VALOR:", paymentData.transaction_amount);
    console.log("EMAIL:", paymentData.payer.email);

    const pagamentoMP = await payment.create({
      body: paymentData,
    });

    console.log("MP RESPONSE STATUS:", pagamentoMP.status);
    console.log("MP RESPONSE ID:", pagamentoMP.id);
    console.log(
      "PIX DATA:",
      pagamentoMP.point_of_interaction?.transaction_data
    );

*/

  /* ======================================================
     MERCADO PAGO
  ====================================================== */
  const client = new MercadoPagoConfig({
    accessToken: process.env.MP_ACCESS_TOKEN,
  });

  const payment = new Payment(client);


 const paymentData = {
      transaction_amount: Number(valor), // ex: 120.00
      description: "Pacote PetDay",
      payment_method_id: "pix",
      payer: {
        email: emailPagamento,
      },
  };
 
  console.log("MP TOKEN PREFIX:", process.env.MP_ACCESS_TOKEN.slice(0, 5));
  console.log("VALOR:", paymentData.transaction_amount);
  console.log("EMAIL:", paymentData.payer.email);

  const response = await mercadopago.payment.create(paymentData);

  console.log("MP RESPONSE STATUS:", response.status);
  console.log("MP RESPONSE BODY:", response.body);



  const pagamentoMP = await payment.create({
    body: {
      transaction_amount: valorCentavos / 100,
      description: pacote.nome,
      payer: { email: emailPagamento },
      payment_method_id: formaPagamento === "pix" ? "pix" : undefined,
      installments: formaPagamento === "cartao" ? parcelas : undefined,
    },
  });

  /* ======================================================
     CRIAR PACOTE ADQUIRIDO
  ====================================================== */
  const pacoteAdquiridoRef = await db.collection("pacotes_adquiridos").add({
    tutor_id: auth?.uid ?? null,
    email_pagamento: emailPagamento,

    creche_id: crecheId,
    pacote_id: pacoteId,
    pacote_nome: pacote.nome,

    preferencias: preferencias,

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

  /* ======================================================
     MARCAR INTENÇÃO COMO PROCESSADA
  ====================================================== */
  await intencaoSnap.ref.update({
    status: "pagamento_criado",
    pacote_adquirido_id: pacoteAdquiridoRef.id,
    atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {
    pagamentoId: pagamentoMP.id,
    status: pagamentoMP.status,

    // 🔑 PIX
    pix_qr_code_base64:
      pagamentoMP.point_of_interaction?.transaction_data?.qr_code_base64 ??
      null,

    pix_copia_e_cola:
      pagamentoMP.point_of_interaction?.transaction_data?.qr_code ??
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

/*======================================================
FUNÇÃO:A CRECHE FAZ O CHECK-IN DO ANIMAL
=======================================================*/
exports.checkinReservaAdmin = onCall(async (request) => {
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

/*===============================
FUNÇÃO: ASSOCIA O PACOTE ADQUIRIDO AO TUTOR
==================================*/
exports.associarPacoteAoTutor = onCall(async (request) => {
  const { auth } = request;

  if (!auth) {
    throw new Error("Usuário não autenticado");
  }

  const userId = auth.uid;

  // buscar usuário
  const userSnap = await db
    .collection("usuarios")
    .doc(userId)
    .get();

  if (!userSnap.exists) {
    throw new Error("Usuário não encontrado");
  }

  const userData = userSnap.data();
  const email = userData.email;

  if (!email) {
    throw new Error("Usuário sem email");
  }

  // buscar pacotes pagos ainda não associados
  const pacotesSnap = await db
    .collection("pacotes_adquiridos")
    .where("tutor_id", "==", null)
    .where("email_pagamento", "==", email)
    .where("status", "==", "ativo")
    .get();

  const batch = db.batch();

  pacotesSnap.docs.forEach((doc) => {
    batch.update(doc.ref, {
      tutor_id: userId,
      atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
    });
  });

  await batch.commit();

  return {
    associados: pacotesSnap.size,
  };
});

