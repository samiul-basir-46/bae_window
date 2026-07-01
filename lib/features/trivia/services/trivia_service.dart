import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trivia_model.dart';

class TriviaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<TriviaModel?> watchTrivia(String coupleId, String dateYmd) {
    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('trivia')
        .doc(dateYmd)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return TriviaModel.fromMap(snapshot.data()!);
      }
      return null;
    });
  }

  Future<void> submitAnswer(
    String coupleId,
    String dateYmd,
    String questionText,
    String uid,
    String answer,
  ) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('trivia')
        .doc(dateYmd)
        .set({
      'question': questionText,
      'answers': {
        uid: answer,
      }
    }, SetOptions(merge: true));
  }
}
