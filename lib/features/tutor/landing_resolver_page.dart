import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petday/core/config/app_context.dart';
import 'package:petday/features/tutor/landing_tutor_page.dart';

class LandingResolverPage extends StatefulWidget {
  final String slug;

  const LandingResolverPage({
    super.key,
    required this.slug,
  });

  @override
  State<LandingResolverPage> createState() => _LandingResolverPageState();
}

class _LandingResolverPageState extends State<LandingResolverPage> {

  @override
  void initState() {
    super.initState();

    // 🔍 DEBUG IMPORTANTE
    debugPrint('LandingResolverPage → slug recebido: ${widget.slug}');

    _resolverSlug();
  }

  Future<void> _resolverSlug() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('creches')
          .where('slug', isEqualTo: widget.slug)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        _falha('Creche não encontrada');
        return;
      }

      final doc = snap.docs.first;
      final data = doc.data();

      // 🔑 seta tenant no contexto (cache em memória)
      AppContext.setCreche(
        id: doc.id,
        slug: data['slug'],
        nome: data['nome_creche'],
      );

      if (!mounted) return;

      // 🚀 segue para landing real (SEM criar pilha extra)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LandingTutorPage(),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao resolver slug: $e');
      _falha('Erro ao carregar a creche');
    }
  }

  void _falha(String mensagem) {
    if (!mounted) return;

    // 🔁 volta para "/" e passa mensagem
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (_) => false,
      arguments: mensagem,
    );
  }

  @override
  Widget build(BuildContext context) {
    // tela técnica (loading enquanto resolve)
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
