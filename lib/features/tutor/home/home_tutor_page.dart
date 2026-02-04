import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'home_tutor_pacotes_view.dart';

class HomeTutorPage extends StatefulWidget {
  const HomeTutorPage({super.key});

  @override
  State<HomeTutorPage> createState() => _HomeTutorPageState();
}

class _HomeTutorPageState extends State<HomeTutorPage> {
  Widget _paginaAtual = const HomeTutorPacotesView();

  @override
  void initState() {
    super.initState();
    _associarPacotesAoTutor();
  }

  void _selecionarPagina(Widget pagina) {
    setState(() {
      _paginaAtual = pagina;
    });
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Usuário não autenticado')),
      );
    }

    final nome = user.displayName ?? user.email ?? 'Tutor';
    final foto = user.photoURL;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetDay'),
      ),

      drawer: Drawer(
        child: Column(
          children: [
            /// 🔹 HEADER COM USUÁRIO
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFFEAF5F2),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.teal.shade100,
                    backgroundImage:
                        foto != null ? NetworkImage(foto) : null,
                    child: foto == null
                        ? const Icon(
                            Icons.person,
                            size: 32,
                            color: Colors.teal,
                          )
                        : null,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'PETDAY • Tutor',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// 📦 MENU PRINCIPAL
            ListTile(
              leading: const Icon(Icons.card_membership),
              title: const Text('Meus Pacotes'),
              onTap: () => _selecionarPagina(
                const HomeTutorPacotesView(),
              ),
            ),

            const Spacer(),
            const Divider(),

            /// 🚪 LOGOUT
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),

      body: _paginaAtual,
    );
  }
}

/*====================================
  ASSOCIA PACOTES AO TUTOR NO LOGIN
=====================================*/
Future<void> _associarPacotesAoTutor() async {
  try {
    final callable = FirebaseFunctions.instance
        .httpsCallable('associarPacotesAoTutor');

    final result = await callable.call();

    debugPrint(
      '📦 Pacotes associados: ${result.data['associados']}',
    );
  } catch (e) {
    debugPrint('❌ Erro ao associar pacotes: $e');
  }
}
