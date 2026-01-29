import 'package:cloud_firestore/cloud_firestore.dart';

class PacoteService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> listarPacotesDaCreche({
    required String crecheId,
  }) {
    return _db
        .collection('creches')
        .doc(crecheId)
        .collection('pacotes')
        //.where('ativo', isEqualTo: true)
        .orderBy('ordem')
        .snapshots();
  }
}
