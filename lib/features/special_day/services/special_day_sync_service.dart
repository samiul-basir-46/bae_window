import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/helpers/firestore_cache_service.dart';
import '../models/special_day_model.dart';

class SpecialDaySyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreCacheService _cache = FirestoreCacheService.instance;

  Stream<List<SpecialDayModel>> watchSpecialDays(String coupleId) {
    final query = _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('special_days')
        .orderBy('date', descending: false)
        .limit(50);

    return _cache
        .watchCollectionCacheFirst(
          query: query,
          cacheKey: _cacheKey(coupleId),
          ttl: const Duration(minutes: 10),
        )
        .map((docs) => docs.map((data) {
              final docId = data['id'] as String? ?? '';
              return SpecialDayModel.fromMap(data, docId);
            }).toList());
  }

  Future<void> addSpecialDay(String coupleId, SpecialDayModel day) async {
    final docRef = _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('special_days')
        .doc();

    final finalDay = day.copyWith(id: docRef.id);
    await docRef.set(finalDay.toMap());
    await _cache.remove(_cacheKey(coupleId));
  }

  Future<void> updateSpecialDay(String coupleId, SpecialDayModel day) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('special_days')
        .doc(day.id)
        .set(day.toMap(), SetOptions(merge: true));
    await _cache.remove(_cacheKey(coupleId));
  }

  Future<void> deleteSpecialDay(String coupleId, String dayId) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('special_days')
        .doc(dayId)
        .delete();
    await _cache.remove(_cacheKey(coupleId));
  }

  String _cacheKey(String coupleId) => 'couples/$coupleId/special_days';
}
