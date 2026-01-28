import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petday/core/config/app_context.dart';
import 'package:petday/features/tutor/pagamento/pagamentos_page.dart';

class SelecionarPacotePage extends StatefulWidget {
  const SelecionarPacotePage({super.key});

  @override
  State<SelecionarPacotePage> createState() => _SelecionarPacotePageState();
}

class _SelecionarPacotePageState extends State<SelecionarPacotePage> {
  String? pacoteId;
  String? pacoteNome;
  String? precoFormatado;

  String? racaId;
  String? racaNome;

  final Set<String> datasSelecionadas = {};

  bool carregando = false;
  String? erro;

  /* ======================================================
     CRIAR INTENÇÃO DE COMPRA
  ====================================================== */
  Future<void> _continuar() async {
    if (pacoteId == null || racaId == null) {
      setState(() {
        erro = 'Escolha um pacote e a raça do seu pet 🐾';
      });
      return;
    }

    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final ref =
          await FirebaseFirestore.instance.collection('intencoes_compra').add({
        'creche_id': AppContext.crecheId,
        'pacote_id': pacoteId,
        'pacote_nome': pacoteNome,
        'preco_formatado': precoFormatado,
        'preferencias': {
          'raca_id': racaId,
          'raca_nome': racaNome,
          'datas_pre_selecionadas': datasSelecionadas.toList(),
        },
        'criado_em': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PagamentosPage(intencaoCompraId: ref.id),
        ),
      );
    } catch (_) {
      setState(() {
        erro = 'Erro ao continuar. Tente novamente.';
      });
    } finally {
      setState(() {
        carregando = false;
      });
    }
  }

  /* ======================================================
     UI
  ====================================================== */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F2EC),
      appBar: AppBar(
        title: const Text('Escolha o pacote'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _titulo('🐾 Escolha o pacote ideal'),
            _listaPacotes(),

            const SizedBox(height: 28),

            _titulo('🐶 Raça do seu pet'),
            _seletorRaca(),

            const SizedBox(height: 28),

            _titulo('📅 Datas desejadas (opcional)'),
            _datasPreview(),

            const SizedBox(height: 24),

            if (erro != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  erro!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: carregando ? null : _continuar,
                icon: const Icon(Icons.arrow_forward),
                label: carregando
                    ? const CircularProgressIndicator()
                    : const Text('Continuar para pagamento'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ======================================================
     COMPONENTES VISUAIS
  ====================================================== */

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.brown,
        ),
      ),
    );
  }

  Widget _listaPacotes() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('creches')
          .doc(AppContext.crecheId)
          .collection('pacotes')
          .where('ativo', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final selecionado = pacoteId == doc.id;

            return InkWell(
              onTap: () {
                setState(() {
                  pacoteId = doc.id;
                  pacoteNome = data['nome'];
                  precoFormatado = data['preco_formatado'];
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: selecionado
                      ? const Color(0xFFDCE9D5)
                      : const Color(0xFFEAF5F2),
                  borderRadius: BorderRadius.circular(16),
                  border: selecionado
                      ? Border.all(color: Colors.teal, width: 2)
                      : null,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pets, color: Colors.brown, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['nome'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(data['preco_formatado'] ?? ''),
                        ],
                      ),
                    ),
                    if (selecionado)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.teal,
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _seletorRaca() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('racas')
          .orderBy('nome')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            hintText: 'Selecione a raça',
          ),
          value: racaId,
          items: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: Text(data['nome']),
            );
          }).toList(),
          onChanged: (v) {
            final doc =
                snapshot.data!.docs.firstWhere((d) => d.id == v);
            setState(() {
              racaId = v;
              racaNome = (doc.data() as Map<String, dynamic>)['nome'];
            });
          },
        );
      },
    );
  }

  Widget _datasPreview() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (i) {
        final date = DateTime.now().add(Duration(days: i + 1));
        final iso =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

        final selecionado = datasSelecionadas.contains(iso);

        return ChoiceChip(
          label: Text('${date.day}/${date.month}'),
          selected: selecionado,
          selectedColor: Colors.teal.shade200,
          onSelected: (_) {
            setState(() {
              selecionado
                  ? datasSelecionadas.remove(iso)
                  : datasSelecionadas.add(iso);
            });
          },
        );
      }),
    );
  }
}
