import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import 'package:petday/core/services/pagamento_service.dart';
import 'package:petday/core/config/app_context.dart';

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
  Map<String, dynamic>? pacote;

  String? pacoteAdquiridoId;
  bool pagamentoCriado = false;
  bool pagamentoConfirmado = false;

  StreamSubscription<DocumentSnapshot>? _pacoteSubscription;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  /* ======================================================
     CARREGA INTENÇÃO + PACOTE
  ====================================================== */
  Future<void> _carregarDados() async {
    try {
      final intencaoSnap = await FirebaseFirestore.instance
          .collection('intencoes_compra')
          .doc(widget.intencaoCompraId)
          .get();

      if (!intencaoSnap.exists) {
        setState(() => erro = 'Intenção de compra não encontrada');
        return;
      }

      final intencaoData = intencaoSnap.data()!;
      final pacoteId = intencaoData['pacote_id'];

      final pacoteSnap = await FirebaseFirestore.instance
          .collection('creches')
          .doc(AppContext.crecheId)
          .collection('pacotes')
          .doc(pacoteId)
          .get();

      if (!pacoteSnap.exists) {
        setState(() => erro = 'Pacote não encontrado');
        return;
      }

      setState(() {
        intencao = intencaoData;
        pacote = pacoteSnap.data();
      });
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
      setState(() => erro = 'Erro ao carregar pagamento');
    }
  }

  /* ======================================================
     INICIA PAGAMENTO (PIX)
  ====================================================== */
  Future<void> _pagar() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      setState(() => erro = 'Informe um email válido');
      return;
    }

    setState(() {
      carregando = true;
      erro = null;
    });

    try {
      final resultado = await _pagamentoService.criarPagamento(
        intencaoCompraId: widget.intencaoCompraId,
        formaPagamento: 'pix',
        emailPagamento: email,
      );

      setState(() {
        qrCodePix = base64Decode(resultado['pix_qr_code_base64']);
        pixCopiaECola = resultado['pix_copia_e_cola'];
        pacoteAdquiridoId = resultado['pacoteAdquiridoId'];
        pagamentoCriado = true;
      });

      _iniciarListenerPagamento();
    } catch (e) {
      debugPrint('Erro ao pagar: $e');
      setState(() => erro = 'Erro ao processar pagamento');
    } finally {
      setState(() => carregando = false);
    }
  }

  /* ======================================================
     LISTENER STATUS PAGAMENTO
  ====================================================== */
  void _iniciarListenerPagamento() {
    if (pacoteAdquiridoId == null) return;

    _pacoteSubscription?.cancel();

    _pacoteSubscription = FirebaseFirestore.instance
        .collection('pacotes_adquiridos')
        .doc(pacoteAdquiridoId)
        .snapshots()
        .listen((snapshot) async {
      if (!snapshot.exists || !mounted) return;

      final data = snapshot.data()!;
      if (data['status'] == 'ativo' && !pagamentoConfirmado) {
        pagamentoConfirmado = true;

        final ok = await _mostrarPopupPagamentoConfirmado();
        if (ok == true && mounted) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (_) => false);
        }
      }
    });
  }

  Future<bool?> _mostrarPopupPagamentoConfirmado() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Pagamento confirmado 🎉'),
        content: const Text(
          'Recebemos seu pagamento com sucesso.\n\nFaça login para continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pacoteSubscription?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  /* ======================================================
     UI
  ====================================================== */
  @override
  Widget build(BuildContext context) {
    if (intencao == null || pacote == null) {
      return Scaffold(
        body: Center(
          child: erro != null
              ? Text(erro!, style: const TextStyle(color: Colors.red))
              : const CircularProgressIndicator(),
        ),
      );
    }

    final preco = formatarPreco(pacote!['preco_centavos']);
    final imagemUrl = pacote!['imagem_fundo_url'];

    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// CARD DO PACOTE
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (imagemUrl != null && imagemUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Image.network(
                            imagemUrl,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pacote!['nome'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              preco,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// EMAIL
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    'Email para o pagamento',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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

                const SizedBox(height: 16),

                if (erro != null)
                  Text(erro!, style: const TextStyle(color: Colors.red)),

                if (qrCodePix != null) ...[
                  const SizedBox(height: 24),
                  Image.memory(qrCodePix!, width: 220),
                ],

                if (pixCopiaECola != null) ...[
                  const SizedBox(height: 12),
                  SelectableText(pixCopiaECola!,
                      style: const TextStyle(fontSize: 12)),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('Copiar PIX'),
                    onPressed: () {
                      Clipboard.setData(
                        ClipboardData(text: pixCopiaECola!),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 24),

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

                if (pagamentoCriado)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'Aguardando confirmação do pagamento...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ======================================================
   FORMATADOR DE PREÇO
====================================================== */
String formatarPreco(int precoCentavos) {
  final valor = precoCentavos / 100;
  return 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}';
}
