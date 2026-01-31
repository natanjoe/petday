import 'package:cloud_firestore/cloud_firestore.dart';

class CrecheService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream do documento da creche
  /// Fonte da verdade da Landing Page
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamCreche({
    required String crecheId,
  }) {
    return _firestore
        .collection('creches')
        .doc(crecheId)
        .snapshots();
  }
}
