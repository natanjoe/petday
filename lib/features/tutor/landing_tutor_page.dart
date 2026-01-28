import 'package:flutter/material.dart';
import 'package:petday/features/admin/auth/login_page.dart';
import 'package:petday/features/tutor/selecionar_pacote_page.dart';


class LandingTutorPage extends StatelessWidget {
  const LandingTutorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EC), // bege claro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.pets, color: Colors.brown),
            SizedBox(width: 8),
            Text(
              'PetDay',
              style: TextStyle(
                color: Colors.brown,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text(
              'Entrar',
              style: TextStyle(
                fontSize: 16,
                color: Colors.brown,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // TÍTULO PRINCIPAL
            const Text(
              'Um dia cheio de\nbrincadeiras 🐾',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Colors.brown,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Creche canina com cuidado, carinho e diversão '
              'para o seu melhor amigo.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 32),

            // CARDS VISUAIS (ESTÁTICOS POR ENQUANTO)
            _PacotePreview(
              titulo: 'Aluno ativo',
              descricao: 'Para cães cheios de energia 🐶',
              cor: const Color(0xFFBFD3C1),
            ),
            const SizedBox(height: 16),

            _PacotePreview(
              titulo: 'Aluno feliz',
              descricao: 'Diversão equilibrada e socialização 🐕',
              cor: const Color(0xFFDCE9D5),
            ),
            const SizedBox(height: 16),

            _PacotePreview(
              titulo: 'Aluno exemplar',
              descricao: 'Rotina completa com acompanhamento 🐾',
              cor: const Color(0xFFEAF5F2),
            ),

            const SizedBox(height: 32),

            // CTA PRINCIPAL
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SelecionarPacotePage(),
                    ),
                  );
                },
                icon: const Icon(Icons.pets),
                label: const Text(
                  'Quero conhecer os pacotes',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // RODAPÉ AFETIVO
            Center(
              child: Column(
                children: const [
                  Icon(Icons.favorite, color: Colors.brown, size: 32),
                  SizedBox(height: 8),
                  Text(
                    'Cuidado, atenção e carinho\nem cada detalhe 🐾',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
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
   CARD VISUAL DE PACOTE (APENAS PREVIEW)
====================================================== */

class _PacotePreview extends StatelessWidget {
  final String titulo;
  final String descricao;
  final Color cor;

  const _PacotePreview({
    required this.titulo,
    required this.descricao,
    required this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(
            Icons.pets,
            size: 40,
            color: Colors.brown,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  descricao,
                  style: const TextStyle(color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
