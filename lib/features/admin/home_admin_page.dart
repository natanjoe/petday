import 'package:flutter/material.dart';

class HomeAdminPage extends StatelessWidget {
  const HomeAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PetDay • Admin')),
      body: const Center(
        child: Text(
          'Painel da Creche (Admin)',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
