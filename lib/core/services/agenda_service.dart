import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AgendaService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _docIdFromDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<Map<String, dynamic>> getAgendaDia(DateTime date) async {
    final docId = _docIdFromDate(date);

    final doc = await _db
        .collection('agenda_diaria')
        .doc(docId)
        .get();

    if (!doc.exists) {
      return {
        'ocupacao': {
          'pequeno': 0,
          'medio': 0,
          'grande': 0,
        }
      };
    }

    return doc.data()!;
  }
}