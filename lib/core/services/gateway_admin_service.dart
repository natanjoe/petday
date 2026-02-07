import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petday/core/config/app_context.dart';

class GatewayAdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /* ======================================================
     LISTAR GATEWAYS DE PAGAMENTO DA CRECHE
  ====================================================== */
  Stream<QuerySnapshot<Map<String, dynamic>>> listarGatewaysDaCreche() {
    return _db
        .collection('creches')
        .doc(AppContext.crecheId)
        .collection('pagamentos')
        .snapshots();
  }

  /* ======================================================
     OBTER UM GATEWAY ESPECÍFICO
  ====================================================== */
  Future<DocumentSnapshot<Map<String, dynamic>>> obterGateway(
    String gatewayId,
  ) {
    return _db
        .collection('creches')
        .doc(AppContext.crecheId)
        .collection('pagamentos')
        .doc(gatewayId)
        .get();
  }

  /* ======================================================
     ATUALIZAR CONFIGURAÇÃO DO GATEWAY
  ====================================================== */
  Future<void> atualizarGateway({
    required String gatewayId,
    required Map<String, dynamic> dados,
  }) {
    return _db
        .collection('creches')
        .doc(AppContext.crecheId)
        .collection('pagamentos')
        .doc(gatewayId)
        .update({
      ...dados,
      'atualizado_em': FieldValue.serverTimestamp(),
    });
  }

  /* ======================================================
     ATIVAR UM GATEWAY (DESATIVA OS OUTROS)
     REGRA: SOMENTE UM GATEWAY ATIVO POR CRECHE
  ====================================================== */
  Future<void> ativarGateway(String gatewayId) async {
    final ref = _db
        .collection('creches')
        .doc(AppContext.crecheId)
        .collection('pagamentos');

    final snap = await ref.get();

    final batch = _db.batch();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'ativo': doc.id == gatewayId,
        'atualizado_em': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
