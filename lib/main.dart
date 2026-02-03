import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:petday/features/admin/auth/login_page.dart';
import 'package:petday/features/tutor/landing_resolver_page.dart';

import 'firebase_options.dart';

// PÁGINAS
import 'package:petday/features/tutor/landing_tutor_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const PetDayApp());
}

class PetDayApp extends StatelessWidget {
  const PetDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetDay',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),

      // 🔑 roteador central (multi-tenant)
      onGenerateRoute: _onGenerateRoute,
    );
  }
}

/* ======================================================
   ROUTER CENTRAL (MULTI-TENANT)
====================================================== */
Route<dynamic> _onGenerateRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name ?? '/');

  /*
   * ROOT
   * ex: /
   */
  if (uri.path == '/' || uri.path.isEmpty) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const LandingTutorPage(),
    );
  }

  /*
   * LOGIN
   * ex: /login
   */
  if (uri.path == '/login') {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const LoginPage(),
    );
  }

  /*
   * CRECHE POR SLUG
   * ex: /creches/petday-centro
   */
  if (uri.pathSegments.length == 2 &&
      uri.pathSegments.first == 'creches') {
    final slug = uri.pathSegments[1];

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => LandingResolverPage(slug: slug),
    );
  }

  /*
   * FALLBACK (rota inválida)
   */
  return MaterialPageRoute(
    settings: settings,
    builder: (_) => const Scaffold(
      body: Center(
        child: Text(
          'Página não encontrada',
          style: TextStyle(fontSize: 18),
        ),
      ),
    ),
  );
}
