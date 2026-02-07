import 'dart:convert';
import 'package:http/http.dart' as http;

class PagamentoService {
  /// Endpoint HTTP da Cloud Function (onRequest)
  static const String _baseUrl =
      'https://us-central1-petday-83d9c.cloudfunctions.net/criarPagamento';

  /// Cria um pagamento no backend (PIX ou cartão)
  ///
  /// Retorna:
  /// - qr_code_base64 (PIX)
  /// - pix_copia_e_cola (PIX)
  /// - pacoteAdquiridoId
  Future<Map<String, dynamic>> criarPagamento({
    required String intencaoCompraId,
    required String formaPagamento, // 'pix' | 'cartao'
    required String emailPagamento,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'intencaoCompraId': intencaoCompraId,
          'formaPagamento': formaPagamento,
          'emailPagamento': emailPagamento,
        }),
      );

      if (response.statusCode != 200) {
        final body = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : null;

        throw Exception(
          body?['error'] ?? 'Erro ao criar pagamento no servidor',
        );
      }

      return Map<String, dynamic>.from(
        jsonDecode(response.body),
      );
    } catch (e) {
      throw Exception('Erro ao processar pagamento');
    }
  }
}
