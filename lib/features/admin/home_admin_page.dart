import 'package:flutter/material.dart';
import 'package:petday/core/layout/admin_layout.dart';
import 'package:petday/core/services/config_service.dart';

class HomeAdminPage extends StatelessWidget {
  const HomeAdminPage({super.key});

  
  @override
  Widget build(BuildContext context) {
    final configService = ConfigService();

    return AdminLayout(
      content: FutureBuilder<Map<String, int>>(
        future: configService.getCapacidadePorPorte(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final capacidade = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Capacidade configurada:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text('Pequenos: ${capacidade['pequeno']}'),
              Text('Médios: ${capacidade['medio']}'),
              Text('Grandes: ${capacidade['grande']}'),
            ],
          );
        },
      ),
    );
  }
}
