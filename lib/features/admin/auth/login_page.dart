import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'package:petday/features/tutor/home/home_tutor_page.dart';
import 'package:petday/features/admin/home_admin_page.dart';
import '../../../core/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  String? _error;

  /* ======================================================
     HANDLER CENTRAL DE LOGIN
     - autentica
     - vincula owner automaticamente
     - resolve destino (admin / tutor)
  ====================================================== */
  Future<void> _handleLogin(
    Future<User> Function() loginFn,
  ) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      /* =========================
         1) LOGIN (AUTH)
      ========================= */
      final user = await loginFn();

      /* =========================
         2) VINCULA OWNER (SE FOR)
         - idempotente
         - não bloqueia login
      ========================= */
      try {
        final callable =
            FirebaseFunctions.instance.httpsCallable('vincularOwnerCreche');
        await callable.call();
      } catch (e) {
        debugPrint('vincularOwnerCreche falhou: $e');
      }

      /* =========================
         3) RESOLVE ROLE ATUAL
         (temporário, até migrar 100%)
      ========================= */
      final role = await _authService.getUserRole(user.uid);

      if (!mounted) return;

      /* =========================
         4) NAVEGAÇÃO
      ========================= */
      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeAdminPage(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const HomeTutorPage(),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao entrar: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  /* ======================================================
     MÉTODOS DE LOGIN
  ====================================================== */

  Future<void> _loginWithEmail() async {
    await _handleLogin(() {
      return _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    });
  }

  Future<void> _loginWithGoogle() async {
    await _handleLogin(_authService.signInWithGoogle);
  }

  Future<void> _loginWithApple() async {
    await _handleLogin(_authService.signInWithApple);
  }

  /* ======================================================
     UI
  ====================================================== */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.pets, size: 28),
            SizedBox(width: 8),
            Text(
              'PetDay',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _loading ? null : _loginWithEmail,
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Entrar com Email'),
                ),
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              // 🔵 GOOGLE
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _loginWithGoogle,
                  icon: SvgPicture.asset(
                    'assets/images/google/google_signin_light.svg',
                    height: 28,
                  ),
                  label: const Text('Entrar com Google'),
                ),
              ),

              // 🍎 APPLE (somente iOS nativo)
              if (!kIsWeb && Platform.isIOS) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _loginWithApple,
                    icon: const Icon(Icons.apple),
                    label: const Text('Entrar com Apple'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
