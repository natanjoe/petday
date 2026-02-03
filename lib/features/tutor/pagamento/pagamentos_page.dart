import 'dart:async';
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

  // controle do pagamento
  String? pacoteAdquiridoId;
  bool pagamentoCriado = false;
  bool pagamentoConfirmado = false;

  // listener real do Firestore
  StreamSubscription<DocumentSnapshot>? _pacoteSubscription;

  @override
  void initState() {
    super.initState();
    _carregarIntencao();
  }

  /* ======================================================
     CARREGA INTENÇÃO DE COMPRA
  ====================================================== */
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

  /* ======================================================
     INICIA PAGAMENTO (PIX)
  ====================================================== */
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
        throw Exception('Dados do PIX não retornados');
      }

      setState(() {
        qrCodePix = base64Decode(base64);
        pixCopiaECola = copiaCola;
        pacoteAdquiridoId = resultado['pacoteAdquiridoId'];
        pagamentoCriado = true;
      });

      _iniciarListenerPagamento();
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

  /* ======================================================
     LISTENER DO STATUS DO PAGAMENTO
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

      final data = snapshot.data() as Map<String, dynamic>;
      final statusPacote = data['status'];
      final statusPagamento = data['pagamento']?['status'];

      final confirmado =
          statusPacote == 'ativo' || statusPagamento == 'approved';

      if (confirmado && !pagamentoConfirmado) {
        pagamentoConfirmado = true;

        // mostra popup e aguarda resposta
        final ok = await _mostrarPopupPagamentoConfirmado();

        if (ok == true && mounted) {
          _redirecionarParaLogin();
        }
      }
    });
  }

  /* ======================================================
     POPUP DE CONFIRMAÇÃO
  ====================================================== */
  Future<bool?> _mostrarPopupPagamentoConfirmado() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Pagamento confirmado 🎉'),
        content: const Text(
          'Recebemos seu pagamento com sucesso.\n\n'
          'Faça login para continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /* ======================================================
     REDIRECIONAMENTO FINAL
  ====================================================== */
  void _redirecionarParaLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (_) => false,
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
    if (intencao == null) {
      return Scaffold(
        body: Center(
          child: erro != null
              ? Text(erro!, style: const TextStyle(color: Colors.red))
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
            /// RESUMO
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
            const Text('Email para o pagamento',
                style: TextStyle(fontWeight: FontWeight.bold)),
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

            if (erro != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(erro!, style: const TextStyle(color: Colors.red)),
              ),

            if (qrCodePix != null) ...[
              const SizedBox(height: 16),
              const Center(
                child: Text('Escaneie o QR Code',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Center(
                child: Image.memory(qrCodePix!, width: 220, height: 220),
              ),
            ],

            if (pixCopiaECola != null) ...[
              const SizedBox(height: 16),
              const Text('Ou copie o código PIX:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SelectableText(pixCopiaECola!,
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy),
                label: const Text('Copiar código PIX'),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: pixCopiaECola!),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código PIX copiado')),
                  );
                },
              ),
            ],

            if (pagamentoCriado)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(
                  child: Text(
                    'Aguardando confirmação do pagamento...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

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
          ],
        ),
      ),
    );
  }
}
