import 'package:cloud_functions/cloud_functions.dart';

class PagamentoService {
  /// ⚠️ IMPORTANTE:
  /// As Cloud Functions estão em us-central1
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Cria um pagamento no backend (PIX ou cartão)
  ///
  /// Retorna:
  /// - qr_code_base64 (PIX)
  /// - pix_copia_e_cola (PIX)
  /// - pacoteAdquiridoId
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
      final callable = _functions.httpsCallable('criarPagamento');

      final response = await callable.call({
        'intencaoCompraId': intencaoCompraId,
        'formaPagamento': formaPagamento,
        'emailPagamento': emailPagamento,
      });

      return Map<String, dynamic>.from(response.data);
    } on FirebaseFunctionsException catch (e) {
      throw Exception(
        e.message ?? 'Erro ao criar pagamento no servidor',
      );
    } catch (e) {
      throw Exception('Erro inesperado ao processar pagamento');
    }
  }
}
