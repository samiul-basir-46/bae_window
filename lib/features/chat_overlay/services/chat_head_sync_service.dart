import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bea_window_app/features/chat/models/conversation_model.dart';
import 'overlay_service.dart';

class ChatHeadSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OverlayService _overlayService = OverlayService();

  StreamSubscription? _conversationsSubscription;

  void startSync() {
    _conversationsSubscription?.cancel();
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        _conversationsSubscription?.cancel();
        _overlayService.closeChatHead();
        return;
      }

      final currentUserId = user.uid;

      // Listen to conversations containing this user
      _conversationsSubscription = _firestore
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.docs.isEmpty) return;

        // Get the primary conversation (usually there's only one in a paired app)
        final doc = snapshot.docs.first;
        final conversation = ConversationModel.fromMap(doc.id, doc.data());

        final isEnabled = GetStorage().read<bool>('chat_head_enabled_${conversation.id}') ?? false;
        final isActive = await FlutterOverlayWindow.isActive();

        if (!isEnabled) {
          if (isActive) {
            await _overlayService.closeChatHead();
          }
          return;
        }

        final unreadCount = conversation.unreadCounts[currentUserId] ?? 0;

        // Get partner's details to show their avatar
        final partnerId = conversation.participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );

        String partnerAvatarUrl = '';
        if (partnerId.isNotEmpty) {
          final partnerDoc = await _firestore.collection('users').doc(partnerId).get();
          if (partnerDoc.exists) {
            partnerAvatarUrl = partnerDoc.data()?['profilePicture'] ?? '';
          }
        }

        if (unreadCount > 0) {
          if (!isActive) {
            await _overlayService.showChatHead();
          }
          _overlayService.updateOverlayData({
            'unreadCount': unreadCount,
            'avatarUrl': partnerAvatarUrl,
            'conversationId': conversation.id,
          });
        } else {
          if (isActive) {
            _overlayService.updateOverlayData({
              'unreadCount': 0,
              'avatarUrl': partnerAvatarUrl,
              'conversationId': conversation.id,
            });
          }
        }
      });
    });
  }

  void stopSync() {
    _conversationsSubscription?.cancel();
  }
}
