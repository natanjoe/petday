import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:petday/features/tutor/calendario/calendario_tutor_page.dart';

class HomeTutorPacotesView extends StatelessWidget {
  const HomeTutorPacotesView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pacotes_adquiridos')
          .where('tutor_id', isEqualTo: user!.uid)
          .where('status', isEqualTo: 'ativo')
          .orderBy('criado_em', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (!snapshot.hasData ||
            snapshot.data!.docs.isEmpty) {
          return const _SemPacotesView();
        }

        final pacotes = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pacotes.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final doc = pacotes[index];
            final data =
                doc.data() as Map<String, dynamic>;

            final int diariasTotais =
                data['diarias_totais'] ?? 0;
            final int diariasUsadas =
                data['diarias_usadas'] ?? 0;
            final int diariasDisponiveis =
                diariasTotais - diariasUsadas;

            final Timestamp? criadoEm =
                data['criado_em'];
            final String dataCompra = criadoEm != null
                ? DateFormat('dd/MM/yyyy')
                    .format(criadoEm.toDate())
                : '-';

            return Card(
              color: const Color(0xFFEAF5F2),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['pacote_nome'] ?? 'Pacote',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text('Comprado em $dataCompra'),

                    const SizedBox(height: 8),

                    Text(
                      'Usadas: $diariasUsadas / $diariasTotais',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(
                            Icons.calendar_today),
                        label:
                            const Text('Agendar diária'),
                        onPressed: diariasDisponiveis > 0
                            ? () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        CalendarioTutorPage(
                                      crecheId:
                                          data['creche_id'],
                                      pacoteAdquiridoId:
                                          doc.id,
                                    ),
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _SemPacotesView extends StatelessWidget {
  const _SemPacotesView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Você ainda não possui pacotes ativos.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
