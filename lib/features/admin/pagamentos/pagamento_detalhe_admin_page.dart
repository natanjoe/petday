import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PagamentoDetalheAdminPage extends StatelessWidget {
  final String pacoteAdquiridoId;

  const PagamentoDetalheAdminPage({
    super.key,
    required this.pacoteAdquiridoId,
  });

  String _formatarValor(int centavos) {
    final v = centavos / 100;
    return 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes do pagamento')),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance
            .collection('pacotes_adquiridos')
            .doc(pacoteAdquiridoId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data();
          if (data == null) {
            return const Center(child: Text('Pagamento não encontrado'));
          }

          final pagamento = data['pagamento'] ?? {};

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['pacote_nome'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Valor: ${_formatarValor(data['valor_total_centavos'])}'),
                    Text('Status: ${data['status']}'),
                    Text('Gateway: ${pagamento['gateway']}'),
                    Text('Forma: ${pagamento['metodo']}'),
                    Text('External ID: ${pagamento['external_id']}'),
                    const SizedBox(height: 12),
                    Text('Email pagamento: ${data['email_pagamento']}'),
                    Text(
                      'Tutor associado: ${data['tutor_id'] ?? 'não associado'}',
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
