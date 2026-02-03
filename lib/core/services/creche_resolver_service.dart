import 'package:cloud_firestore/cloud_firestore.dart';

class CrecheResolverService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Resolve slug → crecheId
  ///
  /// Retorna:
  /// - crecheId (String)
  /// Lança exceção se não encontrar ou se estiver inativa
  Future<String> resolverPorSlug(String slug) async {
    final snap = await _db
        .collection('creches')
        .where('slug', isEqualTo: slug)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw Exception('Creche não encontrada');
    }

    final doc = snap.docs.first;
    final data = doc.data();

    if (data['ativo'] != true) {
      throw Exception('Creche desativada');
    }

    return doc.id;
  }
}
