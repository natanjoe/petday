import 'package:cloud_functions/cloud_functions.dart';

class PagamentoService {
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'southamerica-east1');

  /// Cria um pagamento no backend (Pix ou cartão)
  ///
  /// Retorna um Map com dados do pagamento:
  /// - qr_code_base64 (Pix)
  /// - pix_copia_e_cola (Pix)
  /// - pacoteAdquiridoId (se criado imediatamente)
  ///
  /// Fonte da verdade:
  /// - intencoes_compra (entrada)
  /// - pacotes_adquiridos (pós-pagamento)
  Future<Map<String, dynamic>> criarPagamento({
    required String intencaoCompraId,
    required String formaPagamento, // 'pix' | 'cartao'
    required String emailPagamento,
  }) async {
    try {
      final callable =
          _functions.httpsCallable('criarPagamento');

      final response = await callable.call({
        'intencaoCompraId': intencaoCompraId,
        'formaPagamento': formaPagamento,
        'emailPagamento': emailPagamento,
      });

      final data = Map<String, dynamic>.from(response.data);

      return data;
    } on FirebaseFunctionsException catch (e) {
      throw Exception(
        e.message ?? 'Erro ao criar pagamento',
      );
    } catch (e) {
      throw Exception('Erro inesperado ao processar pagamento');
    }
  }
}
