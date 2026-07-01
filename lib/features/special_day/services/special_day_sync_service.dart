import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/special_day_model.dart';

class SpecialDaySyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<SpecialDayModel>> watchSpecialDays(String coupleId) {
    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('special_days')
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SpecialDayModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addSpecialDay(String coupleId, SpecialDayModel day) async {
    final docRef = _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('special_days')
        .doc();
    
    final finalDay = day.copyWith(id: docRef.id);
    await docRef.set(finalDay.toMap());
  }

  Future<void> updateSpecialDay(String coupleId, SpecialDayModel day) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('special_days')
        .doc(day.id)
        .set(day.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteSpecialDay(String coupleId, String dayId) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('special_days')
        .doc(dayId)
        .delete();
  }
}
