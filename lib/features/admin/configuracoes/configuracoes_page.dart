import 'package:flutter/material.dart';
import '../../../core/layout/admin_layout.dart';
import '../../../core/services/config_service.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  final _configService = ConfigService();

  final _pequenoCtrl = TextEditingController();
  final _medioCtrl = TextEditingController();
  final _grandeCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final capacidade = await _configService.getCapacidadePorPorte();

    _pequenoCtrl.text = capacidade['pequeno'].toString();
    _medioCtrl.text = capacidade['medio'].toString();
    _grandeCtrl.text = capacidade['grande'].toString();

    setState(() {
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    await _configService.updateCapacidadePorPorte(
      pequeno: int.parse(_pequenoCtrl.text),
      medio: int.parse(_medioCtrl.text),
      grande: int.parse(_grandeCtrl.text),
    );

    if (!mounted) return;

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configurações salvas com sucesso')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      title: 'Configurações da Creche',
      content: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const Text(
                  'Capacidade por porte',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _numberField('Pequenos', _pequenoCtrl),
                _numberField('Médios', _medioCtrl),
                _numberField('Grandes', _grandeCtrl),

                const SizedBox(height: 24),

                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const CircularProgressIndicator()
                        : const Text('Salvar'),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _numberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
