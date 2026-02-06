const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

/* ======================================================
   INICIALIZAÇÃO DO FIREBASE
====================================================== */
admin.initializeApp();

/* ======================================================
   CONFIGURAÇÕES GLOBAIS
====================================================== */
setGlobalOptions({
  region: "us-central1",
  secrets: ["MP_ACCESS_TOKEN","MP_ACCESS_TOKEN_CRECHE_AUSPEDAGEM_DAKAH"],
});

/* ======================================================
   EXPORTAÇÃO DAS FUNCTIONS
====================================================== */

// Pagamentos
exports.criarPagamento = require("./criar_pagamentos");
exports.mercadoPagoWebhook = require("./mercado_pago_web_hook");

// Reservas
exports.criarReservaTutor = require("./criar_reserva_tutor");
exports.checkinReservaAdmin = require("./checkin_reserva_admin");

// Associação de pacotes
exports.associarPacoteAoTutor = require("./associar_pacote_ao_tutor");
