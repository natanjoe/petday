import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petday/core/services/gateway_admin_service.dart';

class AdminConfiguracaoPagamentosPage extends StatefulWidget {
  const AdminConfiguracaoPagamentosPage({super.key});

  @override
  State<AdminConfiguracaoPagamentosPage> createState() =>
      _AdminConfiguracaoPagamentosPageState();
}

class _AdminConfiguracaoPagamentosPageState
    extends State<AdminConfiguracaoPagamentosPage> {
  final service = GatewayAdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração de Pagamentos'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: service.listarGatewaysDaCreche(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Nenhum gateway configurado'),
            );
          }

          final gateways = snapshot.data!.docs;

          final gatewayAtivoId = gateways
              .where((g) => g.data()['ativo'] == true)
              .map((g) => g.id)
              .firstOrNull;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: gateways.map((doc) {
              final data = doc.data();
              final gatewayId = doc.id;
              final bool ativo = data['ativo'] == true;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// =======================
                      /// TÍTULO + GATEWAY ATIVO
                      /// =======================
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: gatewayId,
                        groupValue: gatewayAtivoId,
                        onChanged: (value) async {
                          if (value != null && value != gatewayAtivoId) {
                            await service.ativarGateway(value);
                          }
                        },
                        title: Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: ativo ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              gatewayId.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(),

                      /// =======================
                      /// PIX
                      /// =======================
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('PIX'),
                        subtitle:
                            const Text('Pagamento instantâneo'),
                        value: data['pix_ativo'] == true,
                        onChanged: ativo
                            ? (v) {
                                service.atualizarGateway(
                                  gatewayId: gatewayId,
                                  dados: {'pix_ativo': v},
                                );
                              }
                            : null,
                      ),

                      /// =======================
                      /// CARTÃO
                      /// =======================
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Cartão de crédito'),
                        subtitle:
                            const Text('Pagamento parcelado'),
                        value: data['cartao_ativo'] == true,
                        onChanged: ativo
                            ? (v) {
                                service.atualizarGateway(
                                  gatewayId: gatewayId,
                                  dados: {'cartao_ativo': v},
                                );
                              }
                            : null,
                      ),

                      /// =======================
                      /// PARCELAMENTO
                      /// =======================
                      if (ativo && data['cartao_ativo'] == true) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue:
                              (data['parcelamento_maximo'] ?? 1).toString(),
                          decoration: const InputDecoration(
                            labelText: 'Parcelamento máximo',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onFieldSubmitted: (v) {
                            final n = int.tryParse(v) ?? 1;
                            service.atualizarGateway(
                              gatewayId: gatewayId,
                              dados: {'parcelamento_maximo': n},
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 12),

                      /// =======================
                      /// SECRET
                      /// =======================
                      TextFormField(
                        initialValue: data['secret_name'],
                        decoration: InputDecoration(
                          labelText: 'Nome do Secret (Firebase)',
                          hintText:
                              'Ex: MP_ACCESS_TOKEN_CRECHE_X',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock),
                          helperText:
                              (data['secret_name'] == null ||
                                      data['secret_name']
                                          .toString()
                                          .isEmpty)
                                  ? 'Secret não configurado'
                                  : 'Secret configurado',
                          helperStyle: TextStyle(
                            color: (data['secret_name'] == null ||
                                    data['secret_name']
                                        .toString()
                                        .isEmpty)
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                        onFieldSubmitted: (v) {
                          service.atualizarGateway(
                            gatewayId: gatewayId,
                            dados: {'secret_name': v},
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
