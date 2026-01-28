/// AppContext
///
/// Contexto global temporário do app.
/// Responsável por manter o estado da creche atual (multi-tenant).
///
/// ⚠️ IMPORTANTE:
/// - NÃO é fonte da verdade
/// - É apenas cache em memória
/// - A fonte da verdade SEMPRE é o backend (Firestore)
///
/// Fluxo atual:
/// - crecheId é fixo (ex: 'default-creche')
///
/// Fluxo futuro (planejado):
/// 1. Usuário acessa landing via slug
///    ex: /creches/petday-centro
/// 2. Backend resolve slug → crecheId
/// 3. AppContext.setCreche(...) é chamado
/// 4. Todo o app passa a usar esse contexto
///
/// Nenhuma tela deve assumir um crecheId hardcoded.
/// Todas devem ler de AppContext.crecheId.
class AppContext {
  /// 🔑 Identificador único da creche atual
  /// (ex: 'petday-centro', 'creche-abc-123')
  static String crecheId = 'auspedagemdakah';

  /// 🌐 Slug público da creche (URL amigável)
  /// (ex: 'petday-centro')
  static String? crecheSlug;

  /// 📛 Nome amigável da creche (opcional)
  static String? crecheNome;

  /// 🧠 Define a creche atual no contexto global
  ///
  /// Deve ser chamado:
  /// - após resolver slug no backend
  /// - ou após login/admin selecionar creche
  static void setCreche({
    required String id,
    String? slug,
    String? nome,
  }) {
    crecheId = id;
    crecheSlug = slug;
    crecheNome = nome;
  }

  /// 🧹 Limpa o contexto
  ///
  /// Pode ser usado em logout ou troca de tenant
  static void clear() {
    crecheId = 'auspedagemdakah';
    crecheSlug = null;
    crecheNome = null;
  }
}
