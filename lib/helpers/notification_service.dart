import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../firebase_options.dart';
import 'all_routes.dart';
import 'navigation_service.dart';
import 'widget_helper.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await PushNotificationService.initializeLocalNotifications();

  if (message.notification == null) {
    await PushNotificationService.showRemoteMessage(message);
  }

  // Always try to update the home screen widget from the FCM data payload,
  // even when the app is fully killed.
  await PushNotificationService.updateWidgetFromMessageData(message.data);
}

class PushNotificationService {
  PushNotificationService._();

  static const String activityChannelId = 'bae_activity';
  static const String pulseChannelId = 'bae_pulse';
  static const String quietChannelId = 'bae_quiet';

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _localNotificationsInitialized = false;
  static bool _listenersInitialized = false;
  static bool _requestingPermission = false;
  static StreamSubscription<User?>? _authSubscription;
  static StreamSubscription<String>? _tokenSubscription;

  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  static Future<void> scheduleSpecialDayNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      if (scheduledDate.isBefore(DateTime.now())) return;

      tz.initializeTimeZones();

      const androidPlatformChannelSpecifics = AndroidNotificationDetails(
        activityChannelId,
        'Bae activity',
        channelDescription: 'Snaps, drawings, voice, pulse, mood and task updates',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosPlatformChannelSpecifics = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosPlatformChannelSpecifics,
      );

      await _localNotifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      dev.log('Scheduled notification: "$title" at $scheduledDate', name: 'PushNotificationService');
    } catch (e) {
      dev.log('Failed to schedule notification: $e', name: 'PushNotificationService');
    }
  }

  static Future<void> initialize() async {
    await initializeLocalNotifications();
    await _messaging.setAutoInitEnabled(true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    if (!_listenersInitialized) {
      _listenersInitialized = true;
      FirebaseMessaging.onMessage.listen(showRemoteMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _openNotification(message.data),
      );
      _tokenSubscription = _messaging.onTokenRefresh.listen(_saveToken);
      _authSubscription = _auth.authStateChanges().listen((user) {
        if (user != null) {
          unawaited(requestPermissionAndRegister());
        }
      });
    }

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Future<void>.delayed(
        const Duration(milliseconds: 800),
        () => _openNotification(initialMessage.data),
      );
    }

    if (_auth.currentUser != null) {
      await requestPermissionAndRegister();
    } else if (Platform.isAndroid) {
      await _registerCurrentToken();
    }
  }

  static Future<void> initializeLocalNotifications() async {
    if (_localNotificationsInitialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          _openNotification(
            Map<String, dynamic>.from(jsonDecode(payload) as Map),
          );
        } catch (_) {
          _openNotification({'route': payload});
        }
      },
    );

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        pulseChannelId,
        'Love pulse',
        description: 'Priority love pulses from your Bae',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 280, 140, 360]),
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        activityChannelId,
        'Bae activity',
        description: 'Snaps, drawings, voice, pulse, mood and task updates',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        quietChannelId,
        'Quiet hours',
        description: 'Silent Bae Window notifications during quiet hours',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
    );
    _localNotificationsInitialized = true;
  }

  static Future<AuthorizationStatus> requestPermissionAndRegister() async {
    if (_requestingPermission) {
      return AuthorizationStatus.notDetermined;
    }
    _requestingPermission = true;
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        await _registerCurrentToken();
      }
      return settings.authorizationStatus;
    } finally {
      _requestingPermission = false;
    }
  }

  static Future<void> _registerCurrentToken() async {
    try {
      if (Platform.isIOS) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken == null) {
          Future<void>.delayed(
            const Duration(seconds: 3),
            _registerCurrentToken,
          );
          return;
        }
      }
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(token);
      }
    } catch (e, stack) {
      dev.log(
        'Could not register FCM token',
        name: 'PushNotificationService',
        error: e,
        stackTrace: stack,
      );
    }
  }

  static Future<void> _saveToken(String token) async {
    dev.log(
      'FCM Token =================> $token',
      name: 'PushNotificationService',
    );
    await GetStorage().write(kKeyFCMToken, token);

    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
      'notificationTimezoneOffsetMinutes':
          DateTime.now().timeZoneOffset.inMinutes,
      'notificationTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<Map<String, dynamic>?> loadSettings() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final rawSettings = snapshot.data()?['notificationSettings'];
    return rawSettings is Map ? Map<String, dynamic>.from(rawSettings) : null;
  }

  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'notificationSettings': settings,
      'notificationTimezoneOffsetMinutes':
          DateTime.now().timeZoneOffset.inMinutes,
      'notificationSettingsUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> createTaskCompletedEvent(String taskTitle) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'latestTaskCompleted': {
        'id': '${user.uid}_${DateTime.now().microsecondsSinceEpoch}',
        'title': taskTitle,
        'completedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    final senderName = await getSenderName();
    unawaited(sendNotificationToPartner(
      title: '✅ $senderName completed a task',
      body: taskTitle,
      type: 'taskCompleted',
      route: 'tasks',
    ));
  }

  static Future<void> createLoveNoteEvent(String note) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).set({
      'latestLoveNote': {
        'id': '${user.uid}_${DateTime.now().microsecondsSinceEpoch}',
        'text': note,
        'sentAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));

    final senderName = await getSenderName();
    unawaited(sendNotificationToPartner(
      title: '💌 Note from $senderName',
      body: note,
      type: 'drawingNote',
    ));
  }

  static Future<void> clearConversationNotifications(String conversationId) async {
    final notificationId = conversationId.hashCode;
    await _localNotifications.cancel(id: notificationId);
    final key = 'unread_msgs_$conversationId';
    await GetStorage().remove(key);
  }

  static Future<void> showRemoteMessage(RemoteMessage message) async {
    await initializeLocalNotifications();
    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
    
    final type = message.data['type']?.toString();
    if (type == 'chat') {
      final conversationId = message.data['conversationId']?.toString() ?? '';
      if (conversationId.isNotEmpty) {
        final activeId = GetStorage().read<String>('active_conversation_id');
        if (activeId == conversationId) {
          // User is currently viewing this conversation, do not show notification
          return;
        }

        final muteExpiry = GetStorage().read<int>('mute_until_$conversationId') ?? 0;
        if (muteExpiry == -1 || (muteExpiry > 0 && DateTime.now().millisecondsSinceEpoch < muteExpiry)) {
          // Conversation is muted
          return;
        }
      }

      final senderName = message.data['senderName']?.toString() ?? title ?? 'Partner';
      final messageText = body ?? message.data['body']?.toString() ?? '';
      
      final key = 'unread_msgs_$conversationId';
      final storage = GetStorage();
      final List<dynamic> rawList = storage.read<List<dynamic>>(key) ?? [];
      final List<String> list = rawList.map((e) => e.toString()).toList();
      list.add(messageText);
      storage.write(key, list);

      final notificationId = conversationId.hashCode;
      final summaryText = '${list.length} new messages';

      final inboxStyle = InboxStyleInformation(
        list,
        contentTitle: senderName,
        summaryText: summaryText,
      );

      final androidDetails = AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Real-time chat messages from your partner',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: inboxStyle,
        groupKey: conversationId,
        setAsGroupSummary: false,
      );

      final darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        threadIdentifier: conversationId,
      );

      await _localNotifications.show(
        id: notificationId,
        title: senderName,
        body: list.length > 1 ? '${list.length} new messages: ${list.last}' : list.last,
        notificationDetails: NotificationDetails(android: androidDetails, iOS: darwinDetails),
        payload: jsonEncode(message.data),
      );

      return;
    }

    if (title == null && body == null) return;

    final isQuiet = message.data['quiet'] == 'true';
    final isPulse = message.data['type'] == 'thinkingPulse';
    final channelId = isPulse
        ? pulseChannelId
        : isQuiet
            ? quietChannelId
            : activityChannelId;
    await _localNotifications.show(
      id: message.messageId?.hashCode ??
          DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          isPulse
              ? 'Love pulse'
              : isQuiet
                  ? 'Quiet hours'
                  : 'Bae activity',
          channelDescription: isPulse
              ? 'Priority love pulses from your Bae'
              : isQuiet
                  ? 'Silent notifications during quiet hours'
                  : 'Bae Window partner activity',
          importance: isPulse
              ? Importance.max
              : isQuiet
                  ? Importance.low
                  : Importance.high,
          priority: isPulse
              ? Priority.max
              : isQuiet
                  ? Priority.low
                  : Priority.high,
          playSound: isPulse || !isQuiet,
          enableVibration: isPulse || !isQuiet,
          vibrationPattern:
              isPulse ? Int64List.fromList([0, 280, 140, 360]) : null,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isQuiet,
        ),
      ),
      payload: jsonEncode(message.data),
    );

    // Update Home Screen Widget
    await updateWidgetFromMessageData(message.data);
  }

  /// Updates the home screen widget from FCM data payload.
  /// Called from both foreground (showRemoteMessage) and background handler.
  static Future<void> updateWidgetFromMessageData(Map<String, dynamic> data) async {
    try {
      final snapUrl = data['latestSnapUrl']?.toString();
      final snapType = data['latestSnapType']?.toString();
      final moodEmoji = data['moodEmoji']?.toString();
      final moodText = data['moodText']?.toString();
      final battery = int.tryParse(data['batteryLevel']?.toString() ?? '');

      if (snapUrl != null || moodEmoji != null || battery != null) {
        final partnerName = data['senderName']?.toString() ?? 'Partner';
        await WidgetHelper.updateWidget(
          isPaired: true,
          partnerName: partnerName,
          daysTogether: null,
          latestSnapUrl: snapUrl,
          latestSnapType: snapType,
          latestImageUrl: (snapType != 'draw' && snapType != 'voice') ? snapUrl : null,
          latestDrawingUrl: snapType == 'draw' ? snapUrl : null,
          latestVoiceUrl: snapType == 'voice' ? snapUrl : null,
          partnerMoodEmoji: moodEmoji,
          partnerMoodText: moodText,
          partnerBatteryLevel: battery,
        );
      }
    } catch (e) {
      dev.log(
        'Error updating widget from FCM data',
        name: 'PushNotificationService',
        error: e,
      );
    }
  }

  static void _openNotification(Map<String, dynamic> data) {
    final route = data['route']?.toString();
    if (route == 'chat') {
      final conversationId = data['conversationId']?.toString() ?? '';
      final partnerUid = data['partnerUid']?.toString() ?? '';

      // Clear notifications for this conversation
      unawaited(clearConversationNotifications(conversationId));

      void navigate() {
        NavigationService.navigatorKey.currentState?.pushNamed(
          Routes.chatScreen,
          arguments: {
            'conversationId': conversationId,
            'partnerUid': partnerUid,
          },
        );
      }

      if (NavigationService.navigatorKey.currentState == null) {
        Future<void>.delayed(const Duration(milliseconds: 800), navigate);
      } else {
        navigate();
      }
      return;
    }

    if (route == 'trivia') {
      final questionText = data['questionText']?.toString() ?? '';
      final coupleId = data['coupleId']?.toString() ?? '';

      void navigate() {
        NavigationService.navigatorKey.currentState?.pushNamed(
          Routes.triviaScreen,
          arguments: {
            'coupleId': coupleId,
            'questionText': questionText,
          },
        );
      }

      if (NavigationService.navigatorKey.currentState == null) {
        Future<void>.delayed(const Duration(milliseconds: 800), navigate);
      } else {
        navigate();
      }
      return;
    }

    final routeName = switch (route) {
      'tasks' => Routes.tasksScreen,
      'profile' => Routes.myProfileScreen,
      _ => Routes.navigationScreen,
    };

    void navigate() {
      NavigationService.navigatorKey.currentState?.pushNamed(routeName);
    }

    if (NavigationService.navigatorKey.currentState == null) {
      Future<void>.delayed(const Duration(milliseconds: 800), navigate);
    } else {
      navigate();
    }
  }

  static Future<String> getSenderName() async {
    final user = _auth.currentUser;
    if (user == null) return "Partner";
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        final nickname = data?['nickname'] as String?;
        if (nickname != null && nickname.isNotEmpty) return nickname;
        final name = data?['name'] as String?;
        if (name != null && name.isNotEmpty) return name;
      }
    } catch (_) {}
    return user.displayName ?? "Partner";
  }

  static String? _cachedAccessToken;
  static DateTime? _tokenExpiresAt;

  static Future<String?> _getAccessToken() async {
    // Return cached token if it's still valid (with 60s buffer)
    if (_cachedAccessToken != null &&
        _tokenExpiresAt != null &&
        DateTime.now().isBefore(_tokenExpiresAt!.subtract(const Duration(seconds: 60)))) {
      return _cachedAccessToken;
    }

    try {
      final serviceAccountJson = await rootBundle.loadString(
        'assets/service-account.json',
      );
      final credentials = auth.ServiceAccountCredentials.fromJson(serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      
      final client = await auth.clientViaServiceAccount(credentials, scopes);
      _cachedAccessToken = client.credentials.accessToken.data;
      _tokenExpiresAt = client.credentials.accessToken.expiry;
      client.close();
      dev.log(
        'FCM access token obtained successfully, expires at $_tokenExpiresAt',
        name: 'PushNotificationService',
      );
      return _cachedAccessToken;
    } catch (e, stack) {
      dev.log(
        'Error getting FCM OAuth2 token. Make sure assets/service-account.json exists.',
        name: 'PushNotificationService',
        error: e,
        stackTrace: stack,
      );
      _cachedAccessToken = null;
      _tokenExpiresAt = null;
      return null;
    }
  }

  static Future<String?> _getPartnerUid() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    try {
      final userSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (!userSnapshot.exists) return null;
      final userData = userSnapshot.data();
      if (userData == null || userData['pairStatus'] != 'paired') return null;
      final pairId = userData['pairId'] as String?;
      if (pairId == null || pairId.isEmpty) return null;
      final coupleSnapshot = await _firestore.collection('couples').doc(pairId).get();
      if (!coupleSnapshot.exists) return null;
      final coupleData = coupleSnapshot.data();
      if (coupleData == null) return null;
      final user1Uid = coupleData['user1Uid'] as String?;
      final user2Uid = coupleData['user2Uid'] as String?;
      return (user1Uid == user.uid) ? user2Uid : user1Uid;
    } catch (_) {
      return null;
    }
  }

  static Future<List<String>> _getPartnerFcmTokens() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final userSnapshot = await _firestore.collection('users').doc(user.uid).get();
      if (!userSnapshot.exists) return [];
      
      final userData = userSnapshot.data();
      if (userData == null || userData['pairStatus'] != 'paired') return [];
      
      final pairId = userData['pairId'] as String?;
      if (pairId == null || pairId.isEmpty) return [];

      final coupleSnapshot = await _firestore.collection('couples').doc(pairId).get();
      if (!coupleSnapshot.exists) return [];

      final coupleData = coupleSnapshot.data();
      if (coupleData == null) return [];

      final user1Uid = coupleData['user1Uid'] as String?;
      final user2Uid = coupleData['user2Uid'] as String?;
      final partnerUid = (user1Uid == user.uid) ? user2Uid : user1Uid;
      if (partnerUid == null || partnerUid.isEmpty) return [];

      final partnerSnapshot = await _firestore.collection('users').doc(partnerUid).get();
      if (!partnerSnapshot.exists) return [];

      final partnerData = partnerSnapshot.data();
      if (partnerData == null) return [];

      final tokens = <String>[];
      if (partnerData['fcmTokens'] is List) {
        for (final t in partnerData['fcmTokens'] as List) {
          if (t is String && t.isNotEmpty) {
            tokens.add(t);
          }
        }
      }
      final singleToken = partnerData['fcmToken'] as String?;
      if (singleToken != null && singleToken.isNotEmpty && !tokens.contains(singleToken)) {
        tokens.add(singleToken);
      }
      
      return tokens;
    } catch (e) {
      dev.log(
        'Error fetching partner FCM tokens',
        name: 'PushNotificationService',
        error: e,
      );
      return [];
    }
  }

  static Future<void> sendNotificationToPartner({
    required String title,
    required String body,
    String? type,
    String? route,
    Map<String, String>? extraData,
  }) async {
    try {
      final tokens = await _getPartnerFcmTokens();
      if (tokens.isEmpty) {
        dev.log('No partner FCM tokens found to send notification.', name: 'PushNotificationService');
        return;
      }

      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        dev.log('Could not obtain FCM access token.', name: 'PushNotificationService');
        return;
      }

      final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      for (final token in tokens) {
        final response = await http.post(
          url,
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({
            'message': {
              'token': token,
              'notification': {
                'title': title,
                'body': body,
              },
              'data': {
                'click_action': 'FLUTTER_NOTIFICATION_CLICK',
                if (type != null) 'type': type,
                if (route != null) 'route': route,
                'title': title,
                'body': body,
                ...?extraData,
              },
              'android': {
                'priority': 'high',
                'notification': {
                  'channel_id': type == 'thinkingPulse' ? pulseChannelId : activityChannelId,
                  'sound': 'default',
                }
              },
              'apns': {
                'headers': {
                  'apns-priority': '10',
                  'apns-push-type': 'alert',
                },
                'payload': {
                  'aps': {
                    'sound': 'default',
                    'badge': 1,
                    'content-available': 1,
                  }
                }
              }
            }
          }),
        );

        if (response.statusCode == 200) {
          dev.log('FCM v1 notification sent to token: $token', name: 'PushNotificationService');
        } else {
          dev.log(
            'FCM v1 failed to send notification: ${response.statusCode} - ${response.body}',
            name: 'PushNotificationService',
          );
          // If the token is unregistered/invalid (404), remove it from the partner's list in Firestore
          if (response.statusCode == 404) {
            try {
              final bodyJson = jsonDecode(response.body);
              final errorCode = bodyJson['error']?['details']?[0]?['errorCode'];
              if (errorCode == 'UNREGISTERED') {
                final partnerUid = await _getPartnerUid();
                if (partnerUid != null && partnerUid.isNotEmpty) {
                  await _firestore.collection('users').doc(partnerUid).update({
                    'fcmTokens': FieldValue.arrayRemove([token]),
                  });
                  dev.log('Removed unregistered FCM token from partner profile.', name: 'PushNotificationService');
                }
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      dev.log(
        'Error sending FCM v1 notification to partner',
        name: 'PushNotificationService',
        error: e,
      );
    }
  }

  static Future<void> sendNotificationToSelf({
    required String title,
    required String body,
  }) async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.isEmpty) {
        dev.log('No FCM token found for current user.', name: 'PushNotificationService');
        return;
      }

      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        dev.log('Could not obtain FCM access token.', name: 'PushNotificationService');
        return;
      }

      final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$projectId/messages:send');

      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': token,
            'notification': {
              'title': title,
              'body': body,
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'title': title,
              'body': body,
            },
            'android': {
              'priority': 'high',
              'notification': {
                'channel_id': activityChannelId,
                'sound': 'default',
              }
            },
            'apns': {
              'payload': {
                'aps': {
                  'sound': 'default',
                  'badge': 1,
                }
              }
            }
          }
        }),
      );

      if (response.statusCode == 200) {
        dev.log('FCM v1 test notification sent successfully to self!', name: 'PushNotificationService');
      } else {
        dev.log(
          'FCM v1 failed to send self notification: ${response.statusCode} - ${response.body}',
          name: 'PushNotificationService',
        );
      }
    } catch (e) {
      dev.log(
        'Error sending self FCM notification',
        name: 'PushNotificationService',
        error: e,
      );
    }
  }

  static Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenSubscription?.cancel();
  }
}
