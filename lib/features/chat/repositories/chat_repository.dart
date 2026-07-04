import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/features/chat/models/conversation_model.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/features/chat/models/user_model.dart';
import 'package:bea_window_app/features/chat/services/chat_cache_service.dart';
import 'package:bea_window_app/features/chat/services/media_upload_service.dart';
import 'package:bea_window_app/features/chat/services/message_service.dart';
import 'package:bea_window_app/features/chat/services/reaction_service.dart';

class ChatRepository {
  final MessageService _messageService = MessageService();
  final ReactionService _reactionService = ReactionService();
  final MediaUploadService _mediaUploadService = MediaUploadService();
  final ChatCacheService _chatCacheService = ChatCacheService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Watch conversation rooms for a user
  Stream<List<ConversationModel>> getConversationsStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ConversationModel.fromMap(doc.id, doc.data()))
              .toList();
          // Sort in memory because firestore compound queries with array-contains require index creation for sorting
          list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return list;
        });
  }

  /// Watch a specific user's presence/profile
  Stream<UserModel> watchUserProfile(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserModel.fromMap(doc.id, doc.data() ?? {}));
  }

  /// Fetch user profile once
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// Watch all registered users (for starting new chats)
  Stream<List<UserModel>> getAllUsersStream(String currentUserId) {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Get messages stream for a conversation
  Stream<List<MessageModel>> getMessagesStream(String conversationId, int limit) {
    return _messageService.getMessagesStream(conversationId, limit);
  }

  /// Create room if needed
  Future<void> ensureConversationExists({
    required String conversationId,
    required List<String> participants,
  }) {
    return _messageService.ensureConversationExists(
      conversationId: conversationId,
      participants: participants,
    );
  }

  /// Send normal messages
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String content,
    required ChatMessageType type,
    RepliedMessageModel? repliedTo,
    String? fileName,
    int? fileSize,
    String? videoThumbnail,
  }) {
    return _messageService.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      type: type,
      repliedTo: repliedTo,
      fileName: fileName,
      fileSize: fileSize,
      videoThumbnail: videoThumbnail,
    );
  }

  /// Mark messages as seen
  Future<void> markMessagesAsSeen({
    required String conversationId,
    required String currentUserId,
  }) {
    return _messageService.markMessagesAsSeen(
      conversationId: conversationId,
      currentUserId: currentUserId,
    );
  }

  /// Edit a message
  Future<void> editMessage({
    required String conversationId,
    required String messageId,
    required String newContent,
  }) {
    return _messageService.editMessage(
      conversationId: conversationId,
      messageId: messageId,
      newContent: newContent,
    );
  }

  /// Update typing status
  Future<void> setTypingStatus({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) {
    return _messageService.setTypingStatus(
      conversationId: conversationId,
      userId: userId,
      isTyping: isTyping,
    );
  }

  /// Reactions
  Future<void> addReaction({
    required String conversationId,
    required String messageId,
    required String userId,
    required String emoji,
  }) {
    return _reactionService.addReaction(
      conversationId: conversationId,
      messageId: messageId,
      userId: userId,
      emoji: emoji,
    );
  }

  Future<void> removeReaction({
    required String conversationId,
    required String messageId,
    required String userId,
  }) {
    return _reactionService.removeReaction(
      conversationId: conversationId,
      messageId: messageId,
      userId: userId,
    );
  }

  /// Caching text drafts
  void saveMessageDraft(String conversationId, String draft) =>
      _chatCacheService.saveMessageDraft(conversationId, draft);

  String getMessageDraft(String conversationId) =>
      _chatCacheService.getMessageDraft(conversationId);

  void clearMessageDraft(String conversationId) =>
      _chatCacheService.clearMessageDraft(conversationId);

  /// Media uploads
  Future<String> uploadImage(File file, {required String conversationId, Function(double)? onProgress}) {
    return _mediaUploadService.uploadImage(file, conversationId: conversationId, onProgress: onProgress);
  }

  Future<String> uploadFile(File file, {required String conversationId, Function(double)? onProgress}) {
    return _mediaUploadService.uploadFile(file, conversationId: conversationId, onProgress: onProgress);
  }

  Future<Map<String, String?>> uploadVideo({
    required File videoFile,
    required String conversationId,
    required Function(double) onProgress,
  }) {
    return _mediaUploadService.uploadVideo(
      videoFile: videoFile,
      conversationId: conversationId,
      onProgress: onProgress,
    );
  }

  Future<void> cancelVideoUpload(String localPath) {
    return _mediaUploadService.cancelVideoUpload(localPath);
  }
}
