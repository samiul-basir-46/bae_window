import 'package:cloud_firestore/cloud_firestore.dart';

class ReactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// React to a message in a conversation
  Future<void> addReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String emoji,
  }) async {
    final docRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    await docRef.update({
      'reactions.$userId': emoji,
    });
  }

  /// Remove reaction from a message
  Future<void> removeReaction({
    required String conversationId,
    required String messageId,
    required String userId,
  }) async {
    final docRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    await docRef.update({
      'reactions.$userId': FieldValue.delete(),
    });
  }
}
