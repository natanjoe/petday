import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petday/core/services/pet_service.dart';


class CadastroPetPage extends StatefulWidget {
  const CadastroPetPage({super.key});

  @override
  State<CadastroPetPage> createState() => _CadastroPetPageState();
}

class _CadastroPetPageState extends State<CadastroPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();

  String _especie = 'cachorro';
  String? _racaId;
  bool _loading = false;

  final PetService _petService = PetService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar Pet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /// Nome do Pet
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do pet',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Informe o nome do pet';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              /// Espécie
              DropdownButtonFormField<String>(
                value: _especie,
                decoration: const InputDecoration(
                  labelText: 'Espécie',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'cachorro',
                    child: Text('Cachorro'),
                  ),
                  DropdownMenuItem(
                    value: 'gato',
                    child: Text('Gato'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _especie = value!;
                    _racaId = null; // reset raça
                  });
                },
              ),

              const SizedBox(height: 16),

              /// Raça (dinâmica)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('racas')
                    .where('especie', isEqualTo: _especie)
                    .orderBy('nome')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final racas = snapshot.data!.docs;

                  return DropdownButtonFormField<String>(
                    value: _racaId,
                    decoration: const InputDecoration(
                      labelText: 'Raça',
                    ),
                    items: racas.map((doc) {
                      return DropdownMenuItem<String>(
                        value: doc.id,
                        child: Text(doc['nome']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _racaId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Selecione a raça';
                      }
                      return null;
                    },
                  );
                },
              ),

              const SizedBox(height: 32),

              /// Botão Salvar
              ElevatedButton(
                onPressed: _loading ? null : _salvarPet,
                child: _loading
                    ? const CircularProgressIndicator()
                    : const Text('Salvar pet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _salvarPet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await _petService.criarPet(
        tutorId: user.uid,
        nome: _nomeController.text.trim(),
        especie: _especie,
        racaId: _racaId!,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar pet: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}