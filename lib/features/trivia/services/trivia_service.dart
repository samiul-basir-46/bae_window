import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/helpers/firestore_cache_service.dart';
import '../models/trivia_model.dart';

class TriviaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreCacheService _cache = FirestoreCacheService.instance;

  Stream<TriviaModel?> watchTrivia(String coupleId, String dateYmd) {
    final docRef = _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('trivia')
        .doc(dateYmd);

    return _cache
        .watchDocumentCacheFirst(
          ref: docRef,
          cacheKey: 'couples/$coupleId/trivia/$dateYmd',
          ttl: const Duration(minutes: 5),
        )
        .map((data) => data == null ? null : TriviaModel.fromMap(data));
  }

  Future<void> submitAnswer(
    String coupleId,
    String dateYmd,
    String questionText,
    String uid,
    String answer,
  ) async {
    final docRef = _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('trivia')
        .doc(dateYmd);

    final docSnap = await docRef.get();
    if (docSnap.exists) {
      await docRef.update({
        'answers.$uid': answer,
      });
    } else {
      await docRef.set({
        'question': questionText,
        'answers': {
          uid: answer,
        }
      });
    }
    await _cache.remove('couples/$coupleId/trivia/$dateYmd');
  }
}
