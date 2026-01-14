import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user!;
  }

  Future<String> getUserRole(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();

    if (!doc.exists) {
      throw Exception('Usuário não encontrado no sistema');
    }

    return doc.data()!['role'];
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
