import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petday/core/services/gateway_admin_service.dart';

class AdminPagamentosConfigPage extends StatelessWidget {
  AdminPagamentosConfigPage({super.key});

  final GatewayAdminService service = GatewayAdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração de Pagamentos'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.listarGatewaysDaCreche(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhum gateway configurado'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data();

              final ativo = data['ativo'] == true;
              final pixAtivo = data['pix_ativo'] == true;
              final cartaoAtivo = data['cartao_ativo'] == true;
              final secretName = data['secret_name'];

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: ativo ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              doc.id.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Switch(
                            value: ativo,
                            onChanged: (v) async {
                              if (v) {
                                await service.ativarGateway(doc.id);
                              }
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      /// STATUS
                      Text(
                        ativo ? 'Gateway ativo' : 'Gateway inativo',
                        style: TextStyle(
                          color: ativo ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      /// PIX
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('PIX'),
                        subtitle: const Text('Pagamento instantâneo'),
                        value: pixAtivo,
                        onChanged: ativo
                            ? (v) {
                                service.atualizarGateway(
                                  gatewayId: doc.id,
                                  dados: {'pix_ativo': v},
                                );
                              }
                            : null,
                      ),

                      /// CARTÃO
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Cartão de crédito'),
                        subtitle: const Text('Pagamento parcelado'),
                        value: cartaoAtivo,
                        onChanged: ativo
                            ? (v) {
                                service.atualizarGateway(
                                  gatewayId: doc.id,
                                  dados: {'cartao_ativo': v},
                                );
                              }
                            : null,
                      ),

                      const SizedBox(height: 12),

                      /// SECRET
                      Row(
                        children: [
                          const Icon(Icons.lock, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              secretName != null
                                  ? 'Secret configurado'
                                  : 'Secret não configurado',
                              style: TextStyle(
                                fontSize: 12,
                                color: secretName != null
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
