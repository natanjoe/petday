import 'package:flutter/material.dart';
import 'package:petday/core/config/app_context.dart';
import 'package:petday/core/services/creche_resolver_service.dart';
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
  final CrecheResolverService _service = CrecheResolverService();

  String? erro;

  @override
  void initState() {
    super.initState();
    _resolver();
  }

  Future<void> _resolver() async {
    try {
      final crecheId = await _service.resolverPorSlug(widget.slug);

      AppContext.crecheId = crecheId;

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LandingTutorPage(),
        ),
      );
    } catch (e) {
      setState(() {
        erro = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (erro != null) {
      return Scaffold(
        body: Center(
          child: Text(
            erro!,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
