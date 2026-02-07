
/*===========================
➡️ Lista pagamentos já realizados, 
➡️ Fonte: pacotes_adquiridos
➡️ Usado pela AdminPagamentosPage (histórico / financeiro) 
===========================================================*/

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petday/core/config/app_context.dart';

class ListarPagamentoAdminService {
  Stream<QuerySnapshot<Map<String, dynamic>>> listarPagamentosDaCreche() {
    return FirebaseFirestore.instance
        .collection('pacotes_adquiridos')
        .where('creche_id', isEqualTo: AppContext.crecheId)
        .orderBy('criado_em', descending: true)
        .snapshots();
  }
}
