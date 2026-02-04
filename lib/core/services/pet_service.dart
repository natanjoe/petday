import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petday/model/pet_model.dart';

class PetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /* ==============================
   * CRIAR PET
   * ============================== */
  Future<void> criarPet({
    required String tutorId,
    required String nome,
    required String especie,
    required String racaId,
  }) async {
    final porte = await _inferirPorte(racaId);

    await _firestore.collection('pets').add({
      'tutor_id': tutorId,
      'nome': nome,
      'especie': especie,
      'raca_id': racaId,
      'porte': porte,
      'ativo': true,
      'criado_em': FieldValue.serverTimestamp(),
    });
  }

  /* ==============================
   * LISTAR PETS DO TUTOR
   * ============================== */
  Stream<List<PetModel>> listarPetsDoTutor(String tutorId) {
    return _firestore
        .collection('pets')
        .where('tutor_id', isEqualTo: tutorId)
        .where('ativo', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return PetModel.fromFirestore(
              doc.id,
              doc.data(),
            );
          }).toList();
        });
  }

  /* ==============================
   * DESATIVAR PET (SOFT DELETE)
   * ============================== */
  Future<void> desativarPet(String petId) async {
    await _firestore
        .collection('pets')
        .doc(petId)
        .update({'ativo': false});
  }

  /* ==============================
   * INFERIR PORTE (PRIVADO)
   * ============================== */
  Future<String> _inferirPorte(String racaId) async {
    final doc = await _firestore
        .collection('racas')
        .doc(racaId)
        .get();

    if (!doc.exists) {
      throw Exception('Raça não encontrada');
    }

    return doc['porte']; // 'P' | 'M' | 'G'
  }
}
