import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petday/core/services/pagamento_service.dart';

import 'package:flutter/services.dart';


class PagamentosPage extends StatefulWidget {
  final String intencaoCompraId;

  const PagamentosPage({
    super.key,
    required this.intencaoCompraId,
  });

  @override
  State<PagamentosPage> createState() => _PagamentosPageState();
}

class _PagamentosPageState extends State<PagamentosPage> {
  final PagamentoService _pagamentoService = PagamentoService();
  final TextEditingController _emailController = TextEditingController();

  bool carregando = false;
  String? erro;

  Uint8List? qrCodePix;
  String? pixCopiaECola;

  Map<String, dynamic>? intencao;

  //controla o status do pagamento
  String? pacoteAdquiridoId;
  bool pagamentoCriado = false;

  //Popup de pagamento
  bool popupPagamentoMostrado = false;


  @override
  void initState() {
    super.initState();
    _carregarIntencao();
  }

  Future<void> _carregarIntencao() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('intencoes_compra')
          .doc(widget.intencaoCompraId)
          .get();

      if (!doc.exists) {
        setState(() {
          erro = 'Intenção de compra não encontrada';
        });
        return;
      }

      setState(() {
        intencao = doc.data();
      });
    } catch (e) {
      debugPrint('Erro ao carregar intenção: $e');
      setState(() {
        erro = 'Erro ao carregar dados do pagamento';
      });
    }
  }

  Future<void> _pagar() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        erro = 'Informe um email válido para o pagamento';
      });
      return;
    }

    setState(() {
      carregando = true;
      erro = null;
      qrCodePix = null;
    });

    try {
        final resultado = await _pagamentoService.criarPagamento(
          intencaoCompraId: widget.intencaoCompraId,
          formaPagamento: 'pix',
          emailPagamento: email,
        );

        final base64 = resultado['pix_qr_code_base64'];
        final copiaCola = resultado['pix_copia_e_cola'];

        if (base64 == null || copiaCola == null) {
          setState(() {
            erro = 'Dados do PIX não retornados pelo gateway';
          });
          return;
        }

        setState(() {
          qrCodePix = base64Decode(base64);
          pixCopiaECola = copiaCola;
          pacoteAdquiridoId = resultado['pacoteAdquiridoId'];
          pagamentoCriado = true;

        });
      } catch (e) {
        debugPrint('Erro ao pagar: $e');
        setState(() {
          erro = 'Erro ao processar pagamento. Tente novamente.';
        });
      } finally {
        setState(() {
          carregando = false;
        });
      }

  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (intencao == null) {
      return Scaffold(
        body: Center(
          child: erro != null
              ? Text(
                  erro!,
                  style: const TextStyle(color: Colors.red),
                )
              : const CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// RESUMO DO PACOTE
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      intencao!['pacote_nome'] ?? 'Pacote',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(intencao!['preco_formatado'] ?? ''),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// EMAIL
            const Text(
              'Email para o pagamento',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'ex: joao@email.com',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            /// ERRO
            if (erro != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  erro!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            /// QR CODE PIX
            if (qrCodePix != null) ...[
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Escaneie o QR Code para pagar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Image.memory(
                  qrCodePix!,
                  width: 220,
                  height: 220,
                ),
              ),
            ],

          if (pixCopiaECola != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Ou copie o código PIX:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            SelectableText(
              pixCopiaECola!,
              style: const TextStyle(fontSize: 12),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text('Copiar código PIX'),
              onPressed: () {
                Clipboard.setData(
                  ClipboardData(text: pixCopiaECola!),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Código PIX copiado'),
                  ),
                );
              },
            ),
          ],

          //ATIVA O LISTENER QUE ESCUTA A ATUALIZAÇÃO NO FIREBASE.
          if (pagamentoCriado) _escutarConfirmacaoPagamento(),

            const SizedBox(height: 24),

            /// BOTÃO PAGAR, SÓ APARECE ENQUANTO O PAGAMENTO NÃO GEROU QRCODE.
          if (!pagamentoCriado)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: carregando ? null : _pagar,
                child: carregando
                    ? const CircularProgressIndicator()
                    : const Text('Pagar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

//MOSTRA O POPUP DE CONFIRMAÇÃO DE PAGAMENTO
    Future<void> _mostrarPopupPagamentoConfirmado() async {
      if (popupPagamentoMostrado) return;

      popupPagamentoMostrado = true;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Pagamento confirmado 🎉 😄 \u{1F601}'),
          content: const Text(
            'Recebemos seu pagamento com sucesso. Você poderá completar ou editar os dias de alegria do seu aumigo '
            'dentro da área do cliente. \n\n'
            'Faça o login continuar.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // fecha popup
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }


  //ESCUTA A ATUALIZAÇÃO DO WEBHOOK DO MERCADOPAGO PARA REDIRECIONAR O CLIENTE PARA O LOGIN...
  Widget _escutarConfirmacaoPagamento() {
      if (pacoteAdquiridoId == null) {
        return const SizedBox.shrink();
      }

      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pacotes_adquiridos')
            .doc(pacoteAdquiridoId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final status = data?['status'];

         if (status == 'ativo') {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            await _mostrarPopupPagamentoConfirmado();

            if (!mounted) return;

            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (_) => false,
            );
          });
        }


          return const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(
              child: Text(
                'Aguardando confirmação do pagamento...',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      );
    }

}
