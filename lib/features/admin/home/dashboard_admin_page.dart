import 'package:flutter/material.dart';
import '../../../core/layout/admin_layout.dart';
import '../../../core/services/config_service.dart';
import '../../../core/services/agenda_service.dart';

class DashboardAdminPage extends StatelessWidget {
  const DashboardAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final configService = ConfigService();
    final agendaService = AgendaService();
    final hoje = DateTime.now();

    return AdminLayout(
      title: 'Dashboard',
      content: FutureBuilder<List<dynamic>>(
        future: Future.wait([
          configService.getCapacidadePorPorte(),
          agendaService.getAgendaDia(hoje),
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final capacidade =
              snapshot.data![0] as Map<String, int>;
          final agenda =
              snapshot.data![1] as Map<String, dynamic>;

          final ocupacaoMap =
              Map<String, dynamic>.from(agenda['ocupacao'] ?? {});

          final int usadosPequeno =
              (ocupacaoMap['pequeno'] ?? 0) as int;
          final int usadosMedio =
              (ocupacaoMap['medio'] ?? 0) as int;
          final int usadosGrande =
              (ocupacaoMap['grande'] ?? 0) as int;

          return ListView(
            children: [
              _OcupacaoCard(
                titulo: 'Pequenos',
                usados: usadosPequeno,
                total: capacidade['pequeno']!,
              ),
              _OcupacaoCard(
                titulo: 'Médios',
                usados: usadosMedio,
                total: capacidade['medio']!,
              ),
              _OcupacaoCard(
                titulo: 'Grandes',
                usados: usadosGrande,
                total: capacidade['grande']!,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OcupacaoCard extends StatelessWidget {
  final String titulo;
  final int usados;
  final int total;

  const _OcupacaoCard({
    required this.titulo,
    required this.usados,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final int livres = total - usados;
    final double percent =
        total == 0 ? 0.0 : usados / total;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: percent),
            const SizedBox(height: 8),
            Text('$usados usados • $livres vagas livres'),
          ],
        ),
      ),
    );
  }
}
