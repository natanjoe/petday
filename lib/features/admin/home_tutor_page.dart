import 'package:flutter/material.dart';

class HomeTutorPage extends StatelessWidget {
  const HomeTutorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PetDay • Tutor')),
      body: const Center(
        child: Text(
          'Painel do Tutor',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
