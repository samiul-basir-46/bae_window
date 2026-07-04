import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Creates a conversation if it doesn't exist
  Future<void> ensureConversationExists({
    required String conversationId,
    required List<String> participants,
  }) async {
    final docRef = _firestore.collection('conversations').doc(conversationId);
    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'id': conversationId,
        'participants': participants,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCounts': {
          participants[0]: 0,
          participants[1]: 0,
        },
        'lastSeen': {
          participants[0]: FieldValue.serverTimestamp(),
          participants[1]: FieldValue.serverTimestamp(),
        },
        'typing': {
          participants[0]: false,
          participants[1]: false,
        },
        'isGroup': false,
      });
    }
  }

  /// Sends a message and updates conversation metadata
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    required ChatMessageType type,
    RepliedMessageModel? repliedTo,
    String? fileName,
    int? fileSize,
    String? videoThumbnail,
  }) async {
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final message = MessageModel(
      id: messageRef.id,
      senderId: senderId,
      content: content,
      type: type,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      repliedTo: repliedTo,
      fileName: fileName,
      fileSize: fileSize,
      videoThumbnail: videoThumbnail,
    );

    // Save message document
    await messageRef.set(message.toMap());

    // Find recipient UIDs (participants that are not the sender)
    final convDoc = await _firestore.collection('conversations').doc(conversationId).get();
    final participants = List<String>.from(convDoc.data()?['participants'] ?? []);
    final recipients = participants.where((uid) => uid != senderId).toList();

    final updates = <String, dynamic>{
      'lastMessage': message.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Increment unread count for recipients
    for (final recipientId in recipients) {
      updates['unreadCounts.$recipientId'] = FieldValue.increment(1);
    }

    await _firestore.collection('conversations').doc(conversationId).update(updates);
  }

  /// Paginated message stream
  Stream<List<MessageModel>> getMessagesStream(String conversationId, int limit) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Marks unread messages sent by others as seen and resets current user's unread counts
  Future<void> markMessagesAsSeen({
    required String conversationId,
    required String currentUserId,
  }) async {
    final convRef = _firestore.collection('conversations').doc(conversationId);
    
    // 1. Reset current user's unread count and record last seen timestamp
    await convRef.update({
      'unreadCounts.$currentUserId': 0,
      'lastSeen.$currentUserId': FieldValue.serverTimestamp(),
    });

    // 2. Query other user's sent messages in this chat which are not 'seen'
    final unreadQuery = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .get();

    if (unreadQuery.docs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in unreadQuery.docs) {
        if (doc.data()['status'] != 'seen') {
          batch.update(doc.reference, {'status': 'seen'});
        }
      }
      await batch.commit();
      
      // Also update the status of the last message in the conversation, if it's the one we just updated
      final updatedConvDoc = await convRef.get();
      final lastMsgData = updatedConvDoc.data()?['lastMessage'];
      if (lastMsgData != null && lastMsgData['senderId'] != currentUserId) {
        await convRef.update({
          'lastMessage.status': MessageStatus.seen.name,
        });
      }
    }
  }

  /// Edit a sent message
  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String newContent,
  }) async {
    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    await msgRef.update({
      'content': newContent,
      'isEdited': true,
    });

    // Update conversation's lastMessage reference if this message was the latest
    final convRef = _firestore.collection('conversations').doc(conversationId);
    final convDoc = await convRef.get();
    final lastMsgData = convDoc.data()?['lastMessage'];
    if (lastMsgData != null && lastMsgData['id'] == messageId) {
      await convRef.update({
        'lastMessage.content': newContent,
        'lastMessage.isEdited': true,
      });
    }
  }

  /// Sets typing indicators
  Future<void> setTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    await _firestore.collection('conversations').doc(conversationId).update({
      'typing.$userId': isTyping,
    });
  }
}
