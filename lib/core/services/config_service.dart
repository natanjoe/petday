import 'package:cloud_firestore/cloud_firestore.dart';

class ConfigService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String _docId = 'default';
  static const String _collection = 'configuracoes_creche';

  /* =====================
     Leitura
  ===================== */

  Future<Map<String, dynamic>> getConfiguracoes() async {
    final doc =
        await _db.collection(_collection).doc(_docId).get();

    if (!doc.exists) {
      throw Exception('Configurações da creche não encontradas');
    }

    return doc.data()!;
  }

  Future<Map<String, int>> getCapacidadePorPorte() async {
    final data = await getConfiguracoes();
    final capacidade =
        Map<String, dynamic>.from(data['capacidade_por_porte'] ?? {});

    return capacidade.map(
      (key, value) => MapEntry(key, value as int),
    );
  }

  Future<List<Map<String, dynamic>>> getTiposReserva() async {
    final data = await getConfiguracoes();
    return List<Map<String, dynamic>>.from(
      data['tipos_reserva'] ?? [],
    );
  }

  Future<Map<String, dynamic>> getHorarios() async {
    final data = await getConfiguracoes();
    return Map<String, dynamic>.from(data['horarios'] ?? {});
  }

  Future<Map<String, dynamic>> getFuncionamento() async {
    final data = await getConfiguracoes();
    return Map<String, dynamic>.from(data['funcionamento'] ?? {});
  }

  /* =====================
     Escrita
  ===================== */

  Future<void> updateCapacidadePorPorte({
    required int pequeno,
    required int medio,
    required int grande,
  }) async {
    await _db.collection(_collection).doc(_docId).update({
      'capacidade_por_porte': {
        'pequeno': pequeno,
        'medio': medio,
        'grande': grande,
      }
    });
  }

  Future<void> updateHorarios({
    required String checkinInicio,
    required String checkinFim,
    required String checkoutInicio,
    required String checkoutFim,
    required List<String> diasCheckin,
  }) async {
    await _db.collection(_collection).doc(_docId).update({
      'horarios': {
        'checkin_inicio': checkinInicio,
        'checkin_fim': checkinFim,
        'checkout_inicio': checkoutInicio,
        'checkout_fim': checkoutFim,
        'dias_checkin': diasCheckin,
      }
    });
  }

  Future<void> updateFuncionamento({
    required bool permitePernoite,
  }) async {
    await _db.collection(_collection).doc(_docId).update({
      'funcionamento': {
        'permite_pernoite': permitePernoite,
      }
    });
  }

  Future<void> updateTiposReserva(
    List<Map<String, dynamic>> tipos,
  ) async {
    await _db.collection(_collection).doc(_docId).update({
      'tipos_reserva': tipos,
    });
  }
}
