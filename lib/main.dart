import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:petday/features/admin/auth/login_page.dart';
import 'firebase_options.dart';


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
      home: const LoginPage(),
    );
  }
}
