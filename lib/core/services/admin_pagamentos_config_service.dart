import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petday/core/config/app_context.dart';

class AdminPagamentosConfigService {
  CollectionReference<Map<String, dynamic>> _collection() {
    return FirebaseFirestore.instance
        .collection('creches')
        .doc(AppContext.crecheId)
        .collection('pagamentos');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> listarGateways() {
    return _collection().snapshots();
  }

  Future<void> salvarGateway(
    String gatewayId,
    Map<String, dynamic> data,
  ) async {
    await _collection().doc(gatewayId).set(data, SetOptions(merge: true));
  }

  Future<void> ativarGateway(String gatewayId) async {
    final snap = await _collection().get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snap.docs) {
      batch.update(doc.reference, {
        'ativo': doc.id == gatewayId,
      });
    }

    await batch.commit();
  }
}
