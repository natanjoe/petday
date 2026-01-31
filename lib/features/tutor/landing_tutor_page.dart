import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:petday/core/config/app_context.dart';
import 'package:petday/core/services/creche_service.dart';
import 'package:petday/core/services/pacote_service.dart';
import 'package:petday/features/tutor/pagamento/pagamentos_page.dart';

class LandingTutorPage extends StatelessWidget {
  const LandingTutorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pacoteService = PacoteService();
    final crecheService = CrecheService();


    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EC),

appBar: AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: crecheService.streamCreche(
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
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                logoUrl,
                height: 36,
                width: 36,
                fit: BoxFit.cover,
              ),
            )
          else
            const Icon(
              Icons.pets,
              color: Color(0xFF1B5E20), // green[900]
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nomeCreche,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF00796B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    },
  ),

  actions: [
    IconButton(
      icon: const Icon(Icons.more_vert, color: Colors.brown),
      onPressed: () {
        _abrirMenu(context, crecheService);
      },
    ),
  ],
),


      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escolha o pacote ideal\npara o seu pet 🐾',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pacotes configurados pela creche, com carinho e cuidado.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            /// LISTA DE PACOTES
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: pacoteService.listarPacotesDaCreche(
                crecheId: AppContext.crecheId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Nenhum pacote disponível no momento 🐶',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  );
                }

                final pacotes = snapshot.data!.docs;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 2 : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: pacotes.length,
                  itemBuilder: (context, index) {
                    final data = pacotes[index].data();

                    return _PacoteCard(
                      titulo: data['nome'],
                      descricao: data['descricao'],
                      preco: data['preco_formatado'],
                      diarias: data['diarias'],
                      imagemFundoUrl: data['imagem_fundo_url'],
                      onTap: () {
                        _criarIntencaoEIrParaPagamento(
                          context: context,
                          pacoteId: pacotes[index].id,
                          pacoteNome: data['nome'],
                          precoFormatado: data['preco_formatado'],
                          diarias: data['diarias']
                          );                        
                      },
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),
            const Center(
              child: Column(
                children: [
                  Icon(Icons.favorite, color: Colors.brown, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Cuidado, atenção e carinho\nem cada detalhe.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*======================================================
    ABRE O MENU FLUTUANTE
  =====================================================*/
  void _abrirMenu(BuildContext context, CrecheService crecheService) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) {
      return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: crecheService.streamCreche(
          crecheId: AppContext.crecheId,
        ),
        builder: (context, snapshot) {
          final data = snapshot.data?.data();
          final loginIconUrl = data?['login'];

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                ListTile(
                  leading: loginIconUrl != null && loginIconUrl.isNotEmpty
                      ? Image.network(
                          loginIconUrl,
                          width: 28,
                          height: 28,
                        )
                      : const Icon(Icons.login, color: Colors.teal),
                  title: const Text(
                    'Entrar na minha conta',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/login');
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}


/* ======================================================
   CARD DE PACOTE
====================================================== */

class _PacoteCard extends StatelessWidget {
  final String titulo;
  final String descricao;
  final String preco;
  final int diarias;
  final String? imagemFundoUrl;
  final VoidCallback onTap;

  const _PacoteCard({
    required this.titulo,
    required this.descricao,
    required this.preco,
    required this.diarias,
    required this.onTap,
    this.imagemFundoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(35),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          image: imagemFundoUrl != null && imagemFundoUrl!.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imagemFundoUrl!),
                  fit: BoxFit.cover,
                )
              : null,
          color: const Color(0xFFBFD3C1),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Color.fromARGB(120, 0, 0, 0),
                Color.fromARGB(200, 0, 0, 0),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.pets, size: 42, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                descricao,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$preco • $diarias diárias',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*===========================================
    CRIA A INTENÇÃO DE COMPRA DO CLIENTE
============================================*/
Future<void> _criarIntencaoEIrParaPagamento({
  required BuildContext context,
  required String pacoteId,
  required String pacoteNome,
  required String precoFormatado,
  required int diarias,
}) async {
  try {
    final ref =
        await FirebaseFirestore.instance.collection('intencoes_compra').add({
      'creche_id': AppContext.crecheId,
      'pacote_id': pacoteId,
      'pacote_nome': pacoteNome,
      'preco_formatado': precoFormatado,
      'diarias': diarias,
      'preferencias': {}, // vazio por enquanto
      'status': 'criada',
      'criado_em': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PagamentosPage(
          intencaoCompraId: ref.id,
        ),
      ),
    );
  } catch (e) {
    debugPrint('Erro ao criar intenção: $e');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Erro ao iniciar pagamento. Tente novamente.'),
      ),
    );
  }
}
