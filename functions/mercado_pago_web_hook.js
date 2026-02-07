const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const { MercadoPagoConfig, Payment } = require("mercadopago");

const db = admin.firestore();

module.exports = onRequest(
  { region: "us-central1" },
  async (req, res) => {
    try {
      const { type, data } = req.body;

      if (type !== "payment" || !data?.id) {
        return res.status(200).send("Ignorado");
      }

      const paymentId = data.id;

      /* =========================================
         BUSCA PACOTE PELO payment.id
      ========================================= */
      const snap = await db
        .collection("pacotes_adquiridos")
        .where("pagamento.id", "==", paymentId)
        .limit(1)
        .get();

      if (snap.empty) {
        console.warn("Pacote não encontrado para payment:", paymentId);
        return res.status(200).send("Ainda não registrado");
      }

      const pacoteDoc = snap.docs[0];
      const pacote = pacoteDoc.data();

      const crecheId = pacote.creche_id;
      if (!crecheId) throw new Error("Pacote sem creche");

      /* =========================================
         CONFIG MP DA CRECHE
      ========================================= */
      const gatewaySnap = await db
        .collection("creches")
        .doc(crecheId)
        .collection("pagamentos")
        .doc("mercadopago")
        .get();

      if (!gatewaySnap.exists || !gatewaySnap.data()?.ativo) {
        throw new Error("Gateway MP inativo");
      }

      const secretName = gatewaySnap.data().secret_name;
      const accessToken = process.env[secretName];
      if (!accessToken) throw new Error("Secret não encontrado");

      const client = new MercadoPagoConfig({ accessToken });
      const payment = new Payment(client);
      const mpPayment = await payment.get({ id: paymentId });

      let statusFinal = "pendente_pagamento";
      if (mpPayment.status === "approved") statusFinal = "ativo";
      if (mpPayment.status === "rejected") statusFinal = "cancelado";

      /* =========================================
         ATUALIZA PACOTE
      ========================================= */
      await pacoteDoc.ref.update({
        "pagamento.status": mpPayment.status,
        status: statusFinal,
        atualizado_em: admin.firestore.FieldValue.serverTimestamp(),
      });

      /* =========================================
         TENTA ASSOCIAR TUTOR PELO EMAIL
      ========================================= */
      if (statusFinal === "ativo" && !pacote.tutor_id) {
        const userSnap = await db
          .collection("usuarios")
          .where("email", "==", pacote.email_pagamento)
          .limit(1)
          .get();

        if (!userSnap.empty) {
          await pacoteDoc.ref.update({
            tutor_id: userSnap.docs[0].id,
          });
        }
      }

      return res.status(200).send("OK");
    } catch (err) {
      console.error("Erro webhook MP:", err);
      return res.status(500).send("Erro");
    }
  }
);
