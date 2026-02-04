import 'package:cloud_firestore/cloud_firestore.dart';

class PetModel {
  final String id;
  final String tutorId;
  final String nome;
  final String especie; // 'cachorro' | 'gato'
  final String racaId;
  final String porte; // 'P' | 'M' | 'G' (inferido)
  final bool ativo;
  final DateTime criadoEm;

  PetModel({
    required this.id,
    required this.tutorId,
    required this.nome,
    required this.especie,
    required this.racaId,
    required this.porte,
    required this.ativo,
    required this.criadoEm,
  });

  factory PetModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return PetModel(
      id: id,
      tutorId: data['tutor_id'],
      nome: data['nome'],
      especie: data['especie'],
      racaId: data['raca_id'],
      porte: data['porte'],
      ativo: data['ativo'] ?? true,
      criadoEm: (data['criado_em'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tutor_id': tutorId,
      'nome': nome,
      'especie': especie,
      'raca_id': racaId,
      'porte': porte,
      'ativo': ativo,
      'criado_em': FieldValue.serverTimestamp(),
    };
  }
}
