import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/features/chat/models/user_model.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/helpers/navigation_service.dart';
import 'package:bea_window_app/navigation_screen.dart';

class DeepLinkHelper {
  static StreamSubscription? _widgetClickSubscription;
  static final _appLinks = AppLinks();

  static Future<void> init(BuildContext context) async {
    // 1. Handle launch from widget click (app was closed)
    final Uri? launchedUri = await _appLinks.getInitialLink();
    if (!context.mounted) return;
    if (launchedUri != null) {
      _handleUri(context, launchedUri);
    }

    // 2. Handle clicks while app is in background/foreground
    _widgetClickSubscription?.cancel();
    _widgetClickSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      if (context.mounted) {
        _handleUri(context, uri);
      }
    });
  }

  static void dispose() {
    _widgetClickSubscription?.cancel();
  }

  static void _handleUri(BuildContext context, Uri uri) async {
    // URI format: baewindow://camera, baewindow://draw, etc.
    final path = uri.host; // "camera", "draw", "pulse", "voice", "chat"

    switch (path) {
      case 'home':
        const SwitchTabNotification(0).dispatch(context);
        break;
      case 'camera':
        // Navigate to StoryScreen/Camera
        const SwitchTabNotification(1).dispatch(context);
        break;
      case 'draw':
        // Navigate to SpaceScreen/Draw
        const SwitchTabNotification(2).dispatch(context);
        break;
      case 'pulse':
        // Navigate to HomeScreen/Pulse
        const SwitchTabNotification(0).dispatch(context);
        break;
      case 'voice':
        // Navigate to SpaceScreen/Voice or NestScreen
        const SwitchTabNotification(2).dispatch(context);
        break;
      case 'chat':
        final conversationId = uri.queryParameters['conversationId'];
        if (conversationId != null) {
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId == null) return;

          final parts = conversationId.split('_');
          final partnerUid = parts.firstWhere((id) => id != currentUserId, orElse: () => '');
          if (partnerUid.isEmpty) return;

          try {
            final userDoc = await FirebaseFirestore.instance.collection('users').doc(partnerUid).get();
            if (userDoc.exists && userDoc.data() != null) {
              final partnerUser = UserModel.fromMap(userDoc.id, userDoc.data()!);
              NavigationService.navigatorKey.currentState?.pushNamed(
                Routes.chatDetails,
                arguments: {
                  'conversationId': conversationId,
                  'partnerUser': partnerUser,
                },
              );
            }
          } catch (e) {
            debugPrint('Failed to navigate to chat from deep link: $e');
          }
        }
        break;
    }
  }
}
