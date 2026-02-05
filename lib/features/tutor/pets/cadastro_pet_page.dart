import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import 'package:petday/core/services/pet_service.dart';
import 'package:petday/model/pet_model.dart';

class CadastroPetPage extends StatefulWidget {
  final PetModel? pet;

  const CadastroPetPage({
    super.key,
    this.pet,
  });

  @override
  State<CadastroPetPage> createState() => _CadastroPetPageState();
}

class _CadastroPetPageState extends State<CadastroPetPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  XFile? _imagemSelecionada;
  Uint8List? _imagemBytesWeb;

  String _especie = 'cachorro';
  String? _racaId;
  bool _loading = false;

  final PetService _petService = PetService();

  @override
  void initState() {
    super.initState();

    if (widget.pet != null) {
      _nomeController.text = widget.pet!.nome;
      _especie = widget.pet!.especie;
      _racaId = widget.pet!.racaId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdicao = widget.pet != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdicao ? 'Editar Pet' : 'Cadastrar Pet'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              /// FOTO DO PET
              Center(
                child: GestureDetector(
                  onTap: _selecionarImagem,
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.teal.shade100,
                    backgroundImage: _buildImageProvider(),
                    child: _imagemSelecionada == null &&
                            widget.pet?.imageUrl == null
                        ? const Icon(
                            Icons.pets,
                            size: 40,
                            color: Colors.teal,
                          )
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// NOME
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

              /// ESPÉCIE
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
                    _racaId = null;
                  });
                },
              ),

              const SizedBox(height: 16),

              /// RAÇA (DINÂMICA)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('racas')
                    .where('especie', isEqualTo: _especie)
                    .orderBy('nome')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Text('Nenhuma raça disponível');
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

              /// BOTÃO SALVAR
              ElevatedButton(
                onPressed: _loading ? null : _salvarPet,
                child: _loading
                    ? const CircularProgressIndicator()
                    : Text(
                        isEdicao
                            ? 'Salvar alterações'
                            : 'Salvar pet',
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* =======================
   * IMAGE PROVIDER (WEB + MOBILE)
   * ======================= */
  ImageProvider? _buildImageProvider() {
    if (_imagemSelecionada != null) {
      if (kIsWeb && _imagemBytesWeb != null) {
        return MemoryImage(_imagemBytesWeb!);
      } else {
        return FileImage(File(_imagemSelecionada!.path));
      }
    }

    if (widget.pet?.imageUrl != null) {
      return NetworkImage(widget.pet!.imageUrl!);
    }

    return null;
  }

  /* =======================
   * SALVAR PET (CRIAR / EDITAR)
   * ======================= */
  Future<void> _salvarPet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      String petId;

      if (widget.pet == null) {
        petId = await _petService.criarPet(
          tutorId: user.uid,
          nome: _nomeController.text.trim(),
          especie: _especie,
          racaId: _racaId!,
        );
      } else {
        petId = widget.pet!.id;

        await _petService.editarPet(
          petId: petId,
          nome: _nomeController.text.trim(),
          especie: _especie,
          racaId: _racaId!,
        );
      }

      if (_imagemSelecionada != null) {
        final imageUrl = await _petService.uploadImagemPet(
          tutorId: user.uid,
          petId: petId,
          imageFile: _imagemSelecionada!,
        );

        await FirebaseFirestore.instance
            .collection('pets')
            .doc(petId)
            .update({'pet_image_url': imageUrl});
      }

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

  /* =======================
   * SELECIONAR IMAGEM
   * ======================= */
  Future<void> _selecionarImagem() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imagemSelecionada = pickedFile;
          _imagemBytesWeb = bytes;
        });
      } else {
        setState(() {
          _imagemSelecionada = pickedFile;
        });
      }
    }
  }
}
