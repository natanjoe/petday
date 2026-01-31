import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:petday/core/config/app_context.dart';
import 'package:petday/core/services/creche_service.dart';
import 'package:petday/core/services/pacote_service.dart';

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
                if (logoUrl != null && logoUrl.toString().isNotEmpty)
                  Image.network(
                    logoUrl,
                    height: 36,
                    width: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const Icon(Icons.pets, color: Colors.brown);
                    },
                  )
                else
                  const Icon(Icons.pets, color: Colors.brown),

                const SizedBox(width: 8),
                Text(
                  nomeCreche,
                  style: const TextStyle(
                    color: Colors.brown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
        
actions: [
  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: crecheService.streamCreche(
      crecheId: AppContext.crecheId,
    ),
    builder: (context, snapshot) {
      final data = snapshot.data?.data();
      final loginIconUrl = data?['login'];

      if (loginIconUrl == null || loginIconUrl.toString().isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () {
            Navigator.of(context).pushNamed('/login');
          },
          child: Image.network(
            loginIconUrl,
            height: 80,
            width: 80,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) {
              return const Icon(
                Icons.login,
                color: Colors.brown,
                size: 40,
              );
            },
          ),
        ),
      );
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
                        // próximo passo: criar intenção e ir para pagamento
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
