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
  }
}
