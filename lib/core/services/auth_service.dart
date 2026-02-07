import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:petday/core/config/app_context.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';


class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /* ======================================================
   EMAIL + SENHA
  ====================================================== */
  Future<User> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _ensureUserDocument(cred.user!);
    return cred.user!;
  }

  /* ======================================================
   GOOGLE SIGN-IN (WEB + MOBILE)
  ====================================================== */
  Future<User> signInWithGoogle() async {
    UserCredential cred;

    if (kIsWeb) {
      // 🌐 Flutter Web
      final provider = GoogleAuthProvider();
      cred = await _auth.signInWithPopup(provider);
    } else {
      // 📱 Android / iOS
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Login com Google cancelado');
      }

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      cred = await _auth.signInWithCredential(credential);
    }

    await _ensureUserDocument(cred.user!);
    return cred.user!;
  }

  /* ======================================================
   APPLE SIGN-IN (SÓ MOBILE)
  ====================================================== */
  Future<User> signInWithApple() async {
    if (kIsWeb) {
      throw Exception('Apple Sign-In não suportado no Web');
    }

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final cred = await _auth.signInWithCredential(oauthCredential);

    await _ensureUserDocument(
      cred.user!,
      nome: appleCredential.givenName,
    );

    return cred.user!;
  }

  /* ======================================================
   GARANTE DOCUMENTO EM /usuarios
  ====================================================== */
  Future<void> _ensureUserDocument(
    User user, {
    String? nome,
  }) async {
    final ref = _db.collection('usuarios').doc(user.uid);
    final doc = await ref.get();

    if (doc.exists) return;

    await ref.set({
      'uid': user.uid,
      'email': user.email,
      'nome': nome ?? user.displayName ?? '',
      'role': 'tutor',
      'criado_em': FieldValue.serverTimestamp(),
      'provider': user.providerData.map((p) => p.providerId).toList(),
    });
  }

  /* ======================================================
   ROLE
  ====================================================== */
  Future<String> getUserRole(String uid) async {
    final crecheId = AppContext.crecheId;

    if (crecheId == null || crecheId.isEmpty) {
      // fallback seguro
      return 'tutor';
    }

    final adminRef = _db
        .collection('creches')
        .doc(crecheId)
        .collection('admins')
        .doc(uid);

    final adminSnap = await adminRef.get();

    if (adminSnap.exists && adminSnap.data()?['ativo'] == true) {
      return 'admin';
    }

    return 'tutor';
  }
  
  /* ======================================================
   LOGOUT
  ====================================================== */
  Future<void> signOut() async {
    await _auth.signOut();

    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }
  }
}
