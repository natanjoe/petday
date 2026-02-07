import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petday/core/services/listar_pagamento_admin_service.dart';
import 'package:petday/features/admin/pagamentos/pagamento_detalhe_admin_page.dart';

class AdminPagamentosPage extends StatelessWidget {
  AdminPagamentosPage({super.key});

  final service = ListarPagamentoAdminService();

  Color _statusColor(String status) {
    switch (status) {
      case 'ativo':
        return Colors.green;
      case 'pendente_pagamento':
        return Colors.orange;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatarValor(int centavos) {
    final v = centavos / 100;
    return 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamentos')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.listarPagamentosDaCreche(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nenhum pagamento encontrado'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data();

              final status = data['status'] ?? 'desconhecido';
              final pagamento = data['pagamento'] ?? {};
              final valor = data['valor_total_centavos'] ?? 0;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.circle,
                    color: _statusColor(status),
                    size: 14,
                  ),
                  title: Text(
                    data['pacote_nome'] ?? 'Pacote',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_formatarValor(valor)),
                      Text(
                        data['email_pagamento'] ?? '',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PagamentoDetalheAdminPage(pacoteAdquiridoId: doc.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
