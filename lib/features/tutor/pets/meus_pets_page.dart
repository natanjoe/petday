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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Nenhum pet cadastrado ainda.'),
                  );
                }

                final pets = snapshot.data!;

                return ListView.builder(
                  itemCount: pets.length,
                  itemBuilder: (context, index) {
                    final pet = pets[index];

                    return Card(

                      child: ListTile(
                        leading: pet.imageUrl != null
                            ? CircleAvatar(
                                radius: 22,
                                backgroundImage: NetworkImage(pet.imageUrl!),
                                backgroundColor: Colors.teal.shade100,
                              )
                            : const CircleAvatar(
                                radius: 22,
                                backgroundColor: Color(0xFFE0F2F1),
                                child: Icon(
                                  Icons.pets,
                                  color: Colors.teal,
                                ),
                              ),

                        title: Text(
                          pet.nome,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        subtitle: Text(pet.especie),

                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'editar') {
                              _editarPet(context, pet);
                            } else if (value == 'desativar') {
                              _confirmarDesativacao(context, pet);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'editar',
                              child: Text('Editar'),
                            ),
                            PopupMenuItem(
                              value: 'desativar',
                              child: Text('Remover'),
                            ),
                          ],
                        ),
                      )
                    );
                  },
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

  /* ===============================
     EDITAR PET
  =============================== */
  void _editarPet(BuildContext context, PetModel pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CadastroPetPage(pet: pet),
      ),
    );
  }

  /* ===============================
     SOFT DELETE (DESATIVAR PET)
  =============================== */
  void _confirmarDesativacao(BuildContext context, PetModel pet) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remover pet'),
        content: Text(
          'Tem certeza que deseja remover o pet "${pet.nome}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await PetService().desativarPet(pet.id);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text(
              'Remover',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
