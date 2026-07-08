import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/helpers/notification_service.dart';
import 'dart:developer' as dev;

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
    List<MediaItemModel>? mediaItems,
    String? messageId,
  }) async {
    final convRef = _firestore.collection('conversations').doc(conversationId);

    // Ensure conversation exists first
    final convDoc = await convRef.get();
    if (!convDoc.exists) {
      final parts = conversationId.split('_');
      if (parts.length == 2) {
        await ensureConversationExists(
          conversationId: conversationId,
          participants: parts,
        );
      }
    }

    final messageRef = messageId != null
        ? convRef.collection('messages').doc(messageId)
        : convRef.collection('messages').doc();

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
      mediaItems: mediaItems,
    );

    // Save message document
    await messageRef.set(message.toMap());

    // Safely update conversation metadata and increment unread counts using a transaction in background
    unawaited(_firestore.runTransaction((transaction) async {
      final freshConvDoc = await transaction.get(convRef);
      if (!freshConvDoc.exists) return;

      final participants =
          List<String>.from(freshConvDoc.data()?['participants'] ?? []);
      final recipients = participants.where((uid) => uid != senderId).toList();

      final updates = <String, dynamic>{
        'lastMessage': message.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      for (final recipientId in recipients) {
        final currentCount =
            (freshConvDoc.data()?['unreadCounts']?[recipientId] as int?) ?? 0;
        updates['unreadCounts.$recipientId'] = currentCount + 1;
      }

      transaction.update(convRef, updates);
    }).catchError((e) {
      dev.log('Transaction failed: $e', name: 'MessageService');
    }));

    // Send FCM notification to partner in background
    unawaited(() async {
      try {
        final senderName = await PushNotificationService.getSenderName();
        String bodySnippet = '';
        switch (type) {
          case ChatMessageType.image:
            bodySnippet = '📷 Photo';
            break;
          case ChatMessageType.video:
            bodySnippet = '🎥 Video';
            break;
          case ChatMessageType.file:
            bodySnippet = '📁 File';
            break;
          default:
            bodySnippet = content;
        }

        await PushNotificationService.sendNotificationToPartner(
          title: senderName,
          body: bodySnippet,
          type: 'chat',
          route: 'chat',
          extraData: {
            'conversationId': conversationId,
            'partnerUid': senderId,
            'senderName': senderName,
          },
        );
      } catch (e) {
        dev.log('Failed to send message notification: $e',
            name: 'MessageService');
      }
    }());
  }

  Stream<List<MessageModel>> getMessagesStream(
      String conversationId, int limit) {
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

  Future<void> markMessagesAsSeen({
    required String conversationId,
    required String currentUserId,
  }) async {
    final convRef = _firestore.collection('conversations').doc(conversationId);

    await convRef.update({
      'unreadCounts.$currentUserId': 0,
      'lastSeen.$currentUserId': FieldValue.serverTimestamp(),
    });

    final unreadQuery = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: currentUserId)
        .limit(100)
        .get();

    final unreadDocs = unreadQuery.docs
        .where((doc) => doc.data()['status'] != 'seen')
        .toList();

    if (unreadDocs.isNotEmpty) {
      final batch = _firestore.batch();
      for (final doc in unreadDocs) {
        batch.update(doc.reference, {'status': 'seen'});
      }
      await batch.commit();

      // Also update the status of the last message in the conversation
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

  Future<void> setTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    // Set with merge options so it doesn't fail if the document is being created
    await _firestore.collection('conversations').doc(conversationId).set({
      'typing': {
        userId: isTyping,
      }
    }, SetOptions(merge: true));
  }

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
    required String userId,
    required bool deleteForEveryone,
  }) async {
    final msgRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    if (deleteForEveryone) {
      await msgRef.update({
        'content': 'Message deleted',
        'isDeleted': true,
        'type': ChatMessageType.text.name,
        'reactions': {},
        'fileName': null,
        'fileSize': null,
        'videoThumbnail': null,
        'mediaItems': null,
      });

      // Update lastMessage if it matches the deleted message
      final convRef =
          _firestore.collection('conversations').doc(conversationId);
      final convDoc = await convRef.get();
      final lastMsgData = convDoc.data()?['lastMessage'];
      if (lastMsgData != null && lastMsgData['id'] == messageId) {
        await convRef.update({
          'lastMessage.content': 'Message deleted',
          'lastMessage.isDeleted': true,
          'lastMessage.type': ChatMessageType.text.name,
          'lastMessage.reactions': {},
          'lastMessage.fileName': null,
          'lastMessage.fileSize': null,
          'lastMessage.videoThumbnail': null,
          'lastMessage.mediaItems': null,
        });
      }
    } else {
      await msgRef.update({
        'deletedFor': FieldValue.arrayUnion([userId]),
      });
    }
  }
}
