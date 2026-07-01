import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:bea_window_app/navigation_screen.dart';
import 'package:bea_window_app/helpers/all_routes.dart';

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

  static void _handleUri(BuildContext context, Uri uri) {
    // URI format: baewindow://camera, baewindow://draw, etc.
    final path = uri.host; // "camera", "draw", "pulse", "voice"

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
      case 'verify':
        final token = uri.queryParameters['token'];
        final uid = uri.queryParameters['uid'];
        if (token != null && uid != null) {
          Navigator.pushNamed(
            context,
            Routes.verifyingScreen,
            arguments: {'token': token, 'uid': uid},
          );
        }
        break;
      case 'voice':
        // Navigate to SpaceScreen/Voice or NestScreen
        const SwitchTabNotification(2).dispatch(context);
        break;
    }
  }
}
