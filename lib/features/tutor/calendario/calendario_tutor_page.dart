import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DiaStatus {
  disponivel,
  reservado,
  usado,
  indisponivel,
}

class CalendarioTutorPage extends StatefulWidget {
  final String crecheId;
  final String pacoteAdquiridoId;

  const CalendarioTutorPage({
    super.key,
    required this.crecheId,
    required this.pacoteAdquiridoId,
  });

  @override
  State<CalendarioTutorPage> createState() =>
      _CalendarioTutorPageState();
}

class _CalendarioTutorPageState
    extends State<CalendarioTutorPage> {
  final user = FirebaseAuth.instance.currentUser;

  /// dataISO -> checkin
  final Map<String, bool> reservas = {};

  /// datas ISO
  final Set<String> diasLotados = {};

  int diariasTotais = 0;
  int diariasUsadas = 0;

  bool loading = true;
  bool criandoReserva = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  /* ===============================
     CARREGAMENTO DE DADOS
  =============================== */

  Future<void> _carregarDados() async {
    setState(() => loading = true);

    await Future.wait([
      _carregarPacote(),
      _carregarReservas(),
      _carregarAgenda(),
    ]);

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> _carregarPacote() async {
    final snap = await FirebaseFirestore.instance
        .collection('pacotes_adquiridos')
        .doc(widget.pacoteAdquiridoId)
        .get();

    if (!snap.exists) return;

    final data = snap.data()!;
    diariasTotais = data['diarias_totais'] ?? 0;
    diariasUsadas = data['diarias_usadas'] ?? 0;
  }

  Future<void> _carregarReservas() async {
    final snap = await FirebaseFirestore.instance
        .collection('reservas')
        .where('pacote_adquirido_id',
          isEqualTo: widget.pacoteAdquiridoId)
        .where('tutor_id',
          isEqualTo: user!.uid)
        .get();

    reservas.clear();

    for (final doc in snap.docs) {
      final data = doc.data();
      final String dataISO = data['data'];
      final bool checkin = data['checkin'] == true;
      reservas[dataISO] = checkin;
    }
  }

  Future<void> _carregarAgenda() async {
    final snap = await FirebaseFirestore.instance
        .collection('creches')
        .doc(widget.crecheId)
        .collection('agenda_diaria')
        .get();

    diasLotados.clear();

    for (final doc in snap.docs) {
      final data = doc.data();
      final Map<String, dynamic>? limite = data['limite'];
      final Map<String, dynamic>? ocupadas = data['ocupadas'];

      if (limite == null || ocupadas == null) continue;

      bool lotado = false;

      for (final key in limite.keys) {
        final int lim = limite[key] ?? 0;
        final int ocu = ocupadas[key] ?? 0;
        if (ocu >= lim) {
          lotado = true;
          break;
        }
      }

      if (lotado) {
        diasLotados.add(doc.id); // doc.id = dataISO
      }
    }
  }

  /* ===============================
     REGRAS DE NEGÓCIO
  =============================== */

  int get diariasDisponiveis =>
      diariasTotais - diariasUsadas;

  bool _dataPassada(DateTime date) {
    final hoje = DateTime.now();
    final d = DateTime(date.year, date.month, date.day);
    final h = DateTime(hoje.year, hoje.month, hoje.day);
    return d.isBefore(h);
  }

  DiaStatus statusDoDia(String dataISO, DateTime date) {
    if (_dataPassada(date)) {
      return DiaStatus.indisponivel;
    }

    if (reservas.containsKey(dataISO)) {
      return reservas[dataISO]!
          ? DiaStatus.usado
          : DiaStatus.reservado;
    }

    if (diasLotados.contains(dataISO)) {
      return DiaStatus.indisponivel;
    }

    if (diariasDisponiveis <= 0) {
      return DiaStatus.indisponivel;
    }

    return DiaStatus.disponivel;
  }

  Color corDoStatus(DiaStatus status) {
    switch (status) {
      case DiaStatus.disponivel:
        return Colors.green;
      case DiaStatus.reservado:
        return Colors.orange;
      case DiaStatus.usado:
        return Colors.red;
      case DiaStatus.indisponivel:
        return Colors.grey.shade400;
    }
  }

  /* ===============================
     AÇÕES
  =============================== */

  Future<void> _criarReserva(String dataISO) async {
    if (user == null || criandoReserva) return;

    if (diariasDisponiveis <= 0) {
      _mostrarMensagem(
          'Você não possui diárias disponíveis');
      return;
    }

    setState(() => criandoReserva = true);

    await FirebaseFirestore.instance
        .collection('reservas')
        .add({
      'tutor_id': user!.uid,
      'creche_id': widget.crecheId,
      'pacote_adquirido_id': widget.pacoteAdquiridoId,
      'data': dataISO,
      'status': 'reservada',
      'checkin': false,
      'origem': 'tutor',
      'criado_em': FieldValue.serverTimestamp(),
    });

    await _carregarReservas();

    if (mounted) {
      setState(() => criandoReserva = false);
    }
  }

  void _mostrarMensagem(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  /* ===============================
     UI
  =============================== */

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendário do Tutor'),
      ),
      body: Column(
        children: [
          _resumoPacote(),
          const Divider(),
          Expanded(child: _calendario()),
        ],
      ),
    );
  }

  Widget _resumoPacote() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _info('Totais', diariasTotais),
          _info('Usadas', diariasUsadas),
          _info(
            'Disponíveis',
            diariasDisponiveis,
            destaque: true,
          ),
        ],
      ),
    );
  }

  Widget _info(String label, int valor,
      {bool destaque = false}) {
    return Column(
      children: [
        Text(label),
        const SizedBox(height: 4),
        Text(
          valor.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: destaque ? Colors.teal : null,
          ),
        ),
      ],
    );
  }

  Widget _calendario() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final date =
            DateTime.now().add(Duration(days: index));
        final dataISO =
            DateFormat('yyyy-MM-dd').format(date);

        final status = statusDoDia(dataISO, date);

        return InkWell(
          onTap: status == DiaStatus.disponivel
              ? () => _criarReserva(dataISO)
              : () {
                  switch (status) {
                    case DiaStatus.reservado:
                      _mostrarMensagem(
                          'Reserva já criada');
                      break;
                    case DiaStatus.usado:
                      _mostrarMensagem(
                          'Diária já utilizada');
                      break;
                    case DiaStatus.indisponivel:
                      _mostrarMensagem(
                          'Dia indisponível');
                      break;
                    default:
                      break;
                  }
                },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: corDoStatus(status),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              DateFormat('dd').format(date),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
