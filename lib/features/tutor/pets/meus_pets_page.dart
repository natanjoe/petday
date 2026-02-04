import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petday/core/services/pet_service.dart';
import 'package:petday/model/pet_model.dart';


import 'cadastro_pet_page.dart';

class MeusPetsPage extends StatelessWidget {
  const MeusPetsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tutorId = FirebaseAuth.instance.currentUser!.uid;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Meus Pets',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<List<PetModel>>(
              stream: PetService().listarPetsDoTutor(tutorId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final pets = snapshot.data!;

                if (pets.isEmpty) {
                  return const Center(
                    child: Text('Nenhum pet cadastrado ainda.'),
                  );
                }

                return ListView(
                  children: pets.map((pet) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.pets),
                        title: Text(pet.nome),
                        subtitle: Text(pet.especie),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Cadastrar Pet'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CadastroPetPage(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
