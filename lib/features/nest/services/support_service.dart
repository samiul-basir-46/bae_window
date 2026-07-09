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

  Future<void> sendSupportMessage({
    required String userId,
    required String text,
    required String userName,
    required String userEmail,
  }) async {
    final chatDocRef = _firestore.collection('support_chats').doc(userId);
    final docSnap = await chatDocRef.get();

    final bool isNewOrRead = !docSnap.exists ||
        docSnap.data()?['lastMessage'] == null ||
        docSnap.data()?['unreadByAdmin'] == false;

    final userMessageRef = chatDocRef.collection('messages').doc();
    final batch = _firestore.batch();

    // 1. Save user's message
    batch.set(userMessageRef, {
      'senderId': userId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (isNewOrRead) {
      // 2. If it's a new or previously read session, append automated support message
      final autoReplyRef = chatDocRef.collection('messages').doc();
      const autoReplyText =
          "Thank you for your message! Our support team has received it and will get back to you shortly.";

      batch.set(autoReplyRef, {
        'senderId': 'admin',
        'text': autoReplyText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      batch.set(
          chatDocRef,
          {
            'lastMessage': autoReplyText,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'unreadByUser': true,
            'unreadByAdmin': true,
            'userName': userName,
            'userEmail': userEmail,
          },
          SetOptions(merge: true));
    } else {
      // 3. Normal follow-up message: just update lastMessage snippet
      batch.set(
          chatDocRef,
          {
            'lastMessage': text,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'unreadByUser': false,
            'unreadByAdmin': true,
            'userName': userName,
            'userEmail': userEmail,
          },
          SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Mark the support chat as read by the user (meaning no unread messages from admin).
  Future<void> markSupportChatAsRead(String userId) async {
    await _firestore.collection('support_chats').doc(userId).set({
      'unreadByUser': false,
    }, SetOptions(merge: true));
  }
}
