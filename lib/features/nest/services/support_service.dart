import 'package:cloud_firestore/cloud_firestore.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream support messages for a user.
  Stream<List<Map<String, dynamic>>> watchSupportMessages(String userId) {
    return _firestore
        .collection('support_chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  /// Send a message from the user to support and update parent chat document.
  Future<void> sendSupportMessage({
    required String userId,
    required String text,
    required String userName,
    required String userEmail,
  }) async {
    final messageRef = _firestore
        .collection('support_chats')
        .doc(userId)
        .collection('messages')
        .doc();

    final batch = _firestore.batch();

    batch.set(messageRef, {
      'senderId': userId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    batch.set(_firestore.collection('support_chats').doc(userId), {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadByUser': false,
      'unreadByAdmin': true,
      'userName': userName,
      'userEmail': userEmail,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  /// Mark the support chat as read by the user (meaning no unread messages from admin).
  Future<void> markSupportChatAsRead(String userId) async {
    await _firestore.collection('support_chats').doc(userId).set({
      'unreadByUser': false,
    }, SetOptions(merge: true));
  }
}
