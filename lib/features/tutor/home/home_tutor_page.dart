import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_tutor_pacotes_view.dart';
import 'package:cloud_functions/cloud_functions.dart';


class HomeTutorPage extends StatefulWidget {
  const HomeTutorPage({super.key});

  @override
  State<HomeTutorPage> createState() => _HomeTutorPageState();

}

class _HomeTutorPageState extends State<HomeTutorPage> {
  Widget _paginaAtual = const HomeTutorPacotesView();

  /*=========
    chama a função para associar o pacote comprado ao cliente o inicio da sessão do usuário
    ======================*/  
  @override
  void initState() {
    super.initState();
    _associarPacotesAoTutor();
  }


  void _selecionarPagina(Widget pagina) {
    setState(() {
      _paginaAtual = pagina;
    });
    Navigator.pop(context); // fecha o drawer
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Usuário não autenticado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PetDay • Tutor'),
      ),

      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFFEAF5F2),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.pets,
                    color: Colors.teal,
                    size: 36,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Área do Tutor',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ],
              ),
            ),

            /// ÚNICA ENTRADA PRINCIPAL DO TUTOR
            ListTile(
              leading: const Icon(Icons.card_membership),
              title: const Text('Meus Pacotes'),
              onTap: () => _selecionarPagina(
                const HomeTutorPacotesView(),
              ),
            ),

            const Spacer(),
            const Divider(),

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
    ASSOCIA O PACOTE COMPRADO AO USUARIO NA HORA DO LOGIN
=======================================*/
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

