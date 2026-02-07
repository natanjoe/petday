import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:petday/core/config/app_context.dart';
import 'package:petday/core/services/creche_service.dart';
import 'package:petday/features/tutor/pets/meus_pets_page.dart';

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
    _associarPacoteAoTutor();
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
  backgroundColor: Colors.white,
  elevation: 1,
  title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: CrecheService().streamCreche(
      crecheId: AppContext.crecheId,
    ),
    builder: (context, snapshot) {
      final data = snapshot.data?.data();
      final logoUrl = data?['logo'];
      final nomeCreche = data?['nome_creche'] ?? 'PetDay';

      return Row(
              children: [
                if (logoUrl != null && logoUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      logoUrl,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  const Icon(
                    Icons.pets,
                    color: Colors.teal,
                    size: 30,
                  ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    nomeCreche,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.teal,
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
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
                        SizedBox(width: 4),
                            Icon(
                              Icons.pets,
                              size: 14,
                              color: Colors.teal,
                        ),                                               ],
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
            /**Meus PETS */
            ListTile(
              leading: const Icon(Icons.pets),
              title: const Text('Meus Pets'),
              onTap: () => _selecionarPagina(
                const MeusPetsPage(),
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
Future<void> _associarPacoteAoTutor() async {
  try {
    final callable = FirebaseFunctions.instance
        .httpsCallable('associarPacoteAoTutor');

    final result = await callable.call();

    debugPrint(
      '📦 Pacotes associados: ${result.data['associados']}',
    );
  } catch (e) {
    debugPrint('❌ Erro ao associar pacotes: $e');
  }
}

