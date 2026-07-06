import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/helpers/firestore_cache_service.dart';
import 'package:intl/intl.dart';
import '../../../helpers/notification_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreCacheService _cache = FirestoreCacheService.instance;

  User? get currentUser => _auth.currentUser;

  /// Send email verification link
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Reload current user profile to refresh status like emailVerified
  Future<void> reloadUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.reload();
    }
  }

  /// Check if the current user's email is verified
  bool isEmailVerified() {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  /// Sign in user with Email and Password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Register user with Email and Password
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      await credential.user!.updateDisplayName(name);
    }
    return credential;
  }

  /// Save user profile details to Firestore
  Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'bio': 'Hey there! I am using Bloom.',
      'profilePicture': '',
      'profileComplete': false,
      'pairStatus': 'none',
    }, SetOptions(merge: true));
    await _cache.remove(_userCacheKey(uid));
  }

  /// Complete profile setup (nickname + avatar URL)
  /// Avatar upload is handled externally (e.g., via CloudinaryService)
  /// and the resulting URL is passed here.
  Future<void> saveProfileSetup({
    required String nickname,
    required String avatarUrl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    await _firestore.collection('users').doc(user.uid).set({
      'nickname': nickname,
      'profilePicture': avatarUrl,
      'profileComplete': true,
    }, SetOptions(merge: true));
    await _cache.remove(_userCacheKey(user.uid));

    if (avatarUrl.isNotEmpty) {
      await user.updatePhotoURL(avatarUrl);
    }
  }

  /// Generate a unique 6-character invite code
  Future<String> generateInviteCode() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    String code;
    bool codeExists = true;

    do {
      code = List.generate(6, (index) => chars[random.nextInt(chars.length)])
          .join();
      final doc = await _firestore.collection('pairing_codes').doc(code).get();
      codeExists = doc.exists;
    } while (codeExists);

    await _firestore.collection('pairing_codes').doc(code).set({
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'used': false,
    });

    await _firestore.collection('users').doc(user.uid).set({
      'inviteCode': code,
    }, SetOptions(merge: true));
    await _cache.remove(_userCacheKey(user.uid));

    return code;
  }

  /// Join with partner's invite code
  Future<void> joinWithCode(String code) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    final codeDoc =
        await _firestore.collection('pairing_codes').doc(code).get();
    if (!codeDoc.exists) {
      throw Exception('Invalid verification code.');
    }

    final data = codeDoc.data()!;
    if (data['used'] == true) {
      throw Exception('This code has already been used.');
    }

    final partnerUid = data['createdBy'] as String;
    if (partnerUid == user.uid) {
      throw Exception('You cannot pair with your own invite code.');
    }

    final coupleId = '${partnerUid}_${user.uid}';

    await _firestore.collection('couples').doc(coupleId).set({
      'user1Uid': partnerUid,
      'user2Uid': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('pairing_codes').doc(code).set({
      'used': true,
    }, SetOptions(merge: true));

    await _firestore.collection('users').doc(user.uid).set({
      'pairId': coupleId,
      'pairStatus': 'paired',
    }, SetOptions(merge: true));

    await _firestore.collection('users').doc(partnerUid).set({
      'pairId': coupleId,
      'pairStatus': 'paired',
    }, SetOptions(merge: true));
    await _cache.remove(_userCacheKey(user.uid));
    await _cache.remove(_userCacheKey(partnerUid));
    await _cache.remove(_coupleCacheKey(coupleId));
  }

  /// Skip pairing step
  Future<void> skipPairing() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    await _firestore.collection('users').doc(user.uid).set({
      'pairStatus': 'unpaired',
    }, SetOptions(merge: true));
    await _cache.remove(_userCacheKey(user.uid));
  }

  /// Retrieve user profile details from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid,
      {GetOptions? options}) async {
    if (options == null) {
      return _cache.getDocument(
        ref: _firestore.collection('users').doc(uid),
        cacheKey: _userCacheKey(uid),
        ttl: const Duration(minutes: 5),
      );
    }

    final doc = await _firestore.collection('users').doc(uid).get(options);
    return doc.exists ? doc.data() : null;
  }

  /// Update user profile details in Firestore & Firebase Auth
  Future<void> updateUserProfile(
    String uid, {
    String? name,
    String? nickname,
    String? relationshipStartDate,
    String? avatarUrl,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) {
      updates['name'] = name;
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
      }
    }
    if (nickname != null) {
      updates['nickname'] = nickname;
    }
    if (relationshipStartDate != null) {
      await updateRelationshipStartDate(uid, relationshipStartDate);
    }
    if (avatarUrl != null) {
      updates['profilePicture'] = avatarUrl;
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePhotoURL(avatarUrl);
      }
    }

    if (updates.isNotEmpty) {
      // Fire-and-forget: Firestore offline persistence writes to local cache
      // immediately, so we don't need to await the server confirmation.
      // Awaiting can hang indefinitely if the device is offline.
      _firestore
          .collection('users')
          .doc(uid)
          .set(updates, SetOptions(merge: true));
      await _cache.remove(_userCacheKey(uid));
    }
  }

  /// Keep the relationship start date identical for both paired users.
  Future<void> updateRelationshipStartDate(String uid, String date) async {
    final userRef = _firestore.collection('users').doc(uid);
    final userData = await getUserProfile(uid);

    final batch = _firestore.batch();
    batch.set(
      userRef,
      {'relationshipStartDate': date},
      SetOptions(merge: true),
    );

    final isPaired = userData?['pairStatus'] == 'paired';
    final pairId = userData?['pairId'] as String?;
    String? partnerUid;

    if (isPaired && pairId != null) {
      final coupleData = await getCoupleData(pairId);

      if (coupleData == null) {
        throw Exception('Paired relationship data was not found.');
      }

      final user1Uid = coupleData['user1Uid'] as String?;
      final user2Uid = coupleData['user2Uid'] as String?;
      partnerUid = user1Uid == uid
          ? user2Uid
          : user2Uid == uid
              ? user1Uid
              : null;

      if (partnerUid == null) {
        throw Exception('Partner could not be resolved for this account.');
      }

      batch.set(
        _firestore.collection('users').doc(partnerUid),
        {'relationshipStartDate': date},
        SetOptions(merge: true),
      );
    }

    await batch.commit();
    await _cache.remove(_userCacheKey(uid));
    if (partnerUid != null) {
      await _cache.remove(_userCacheKey(partnerUid));
    }
  }

  /// Returns a real-time stream of a user's Firestore document
  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<Map<String, dynamic>?> getCoupleData(String pairId) async {
    return _cache.getDocument(
      ref: _firestore.collection('couples').doc(pairId),
      cacheKey: _coupleCacheKey(pairId),
      ttl: const Duration(minutes: 5),
    );
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> coupleStream(String pairId) {
    return _firestore.collection('couples').doc(pairId).snapshots();
  }

  /// Get partner's UID from a couple document
  /// The coupleId format is "{user1Uid}_{user2Uid}"
  Future<String?> getPartnerUid(String coupleId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final data = await getCoupleData(coupleId);
      if (data == null) return null;
      final user1 = data['user1Uid'] as String?;
      final user2 = data['user2Uid'] as String?;

      // Return the UID that is NOT the current user
      if (user1 == user.uid) return user2;
      if (user2 == user.uid) return user1;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Update current user's mood in Firestore
  Future<void> updateMood({required String emoji, required String text}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final userData = (await userRef.get()).data();
    final batch = _firestore.batch();
    batch.set(
        userRef,
        {
          'mood': {'emoji': emoji, 'text': text},
          ..._weeklyEngagementUpdate(),
        },
        SetOptions(merge: true));
    _addCoupleEngagement(batch, userData, user.uid);
    await batch.commit();
    await _cache.remove(_userCacheKey(user.uid));
    final pairId = userData?['pairId'] as String?;
    if (pairId != null) await _cache.remove(_coupleCacheKey(pairId));

    try {
      final senderName = await PushNotificationService.getSenderName();
      unawaited(PushNotificationService.sendNotificationToPartner(
        title: '$emoji $senderName\'s mood changed',
        body: text,
        type: 'moodCheckIn',
        extraData: {
          'moodEmoji': emoji,
          'moodText': text,
          'senderName': senderName,
        },
      ));
    } catch (e) {
      dev.log('Error triggering mood FCM notification client-side: $e');
    }
  }

  Future<void> updateBatteryLevel(int level) async {
    final user = _auth.currentUser;
    if (user == null || level < 0 || level > 100) return;

    await _firestore.collection('users').doc(user.uid).set({
      'batteryLevel': level,
      'batteryUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _cache.remove(_userCacheKey(user.uid));
  }

  /// Send a real-time pulse event through the current user's profile stream.
  Future<void> sendPulse() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    final userRef = _firestore.collection('users').doc(user.uid);
    final userData = (await userRef.get()).data();
    if (userData?['pairStatus'] != 'paired' || userData?['pairId'] == null) {
      throw Exception('Pair with your partner before sending a pulse.');
    }

    final batch = _firestore.batch();
    batch.set(
        userRef,
        {
          'latestPulse': {
            'id': '${user.uid}_${DateTime.now().microsecondsSinceEpoch}',
            'sentAtClientMs': DateTime.now().toUtc().millisecondsSinceEpoch,
            'sentAt': FieldValue.serverTimestamp(),
          },
          ..._weeklyEngagementUpdate(),
        },
        SetOptions(merge: true));
    _addCoupleEngagement(batch, userData, user.uid);
    await batch.commit();
    await _cache.remove(_userCacheKey(user.uid));
    final pairId = userData?['pairId'] as String?;
    if (pairId != null) await _cache.remove(_coupleCacheKey(pairId));

    try {
      final senderName = await PushNotificationService.getSenderName();
      unawaited(PushNotificationService.sendNotificationToPartner(
        title: '💖 $senderName is thinking of you',
        body: 'Your $senderName just sent a love pulse.',
        type: 'thinkingPulse',
      ));
    } catch (e) {
      dev.log('Error triggering pulse FCM notification client-side: $e');
    }
  }

  /// Update current user's latest snap in Firestore
  Future<void> updateLatestSnap({
    required String snapUrl,
    String? snapType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final existingData = (await userRef.get()).data();
    final updates = <String, dynamic>{};

    // Preserve the last item written by older app versions before the shared
    // legacy field is overwritten by a different content type.
    final legacyUrl = existingData?['latestSnapUrl'] as String? ?? '';
    final legacyType =
        (existingData?['latestSnapType'] as String? ?? 'Image').toLowerCase();
    if (legacyUrl.isNotEmpty) {
      final String legacyUrlField;
      final String legacyTimeField;

      switch (legacyType) {
        case 'draw':
          legacyUrlField = 'latestDrawingUrl';
          legacyTimeField = 'latestDrawingTime';
        case 'voice':
          legacyUrlField = 'latestVoiceUrl';
          legacyTimeField = 'latestVoiceTime';
        default:
          legacyUrlField = 'latestImageUrl';
          legacyTimeField = 'latestImageTime';
      }

      final existingLegacySpecificUrl =
          existingData?[legacyUrlField] as String? ?? '';
      if (existingLegacySpecificUrl.isEmpty) {
        updates[legacyUrlField] = legacyUrl;
        final legacyTime = existingData?['lastSnapTime'];
        if (legacyTime != null) {
          updates[legacyTimeField] = legacyTime;
        }
      }
    }

    final normalizedType = (snapType ?? 'Image').toLowerCase();
    final String contentUrlField;
    final String contentTimeField;

    switch (normalizedType) {
      case 'draw':
        contentUrlField = 'latestDrawingUrl';
        contentTimeField = 'latestDrawingTime';
      case 'voice':
        contentUrlField = 'latestVoiceUrl';
        contentTimeField = 'latestVoiceTime';
      default:
        contentUrlField = 'latestImageUrl';
        contentTimeField = 'latestImageTime';
    }

    updates.addAll({
      contentUrlField: snapUrl,
      contentTimeField: FieldValue.serverTimestamp(),
      // Keep these legacy fields for the home-screen widget and old clients.
      'latestSnapUrl': snapUrl,
      'latestSnapType': snapType ?? 'Image',
      'lastSnapTime': FieldValue.serverTimestamp(),
      ..._weeklyEngagementUpdate(),
    });

    final batch = _firestore.batch();
    batch.set(userRef, updates, SetOptions(merge: true));
    _addCoupleEngagement(batch, existingData, user.uid);
    await batch.commit();
    await _cache.remove(_userCacheKey(user.uid));
    final pairId = existingData?['pairId'] as String?;
    if (pairId != null) await _cache.remove(_coupleCacheKey(pairId));

    try {
      final senderName = await PushNotificationService.getSenderName();
      final type = snapType ?? 'Image';
      final String title;
      final String body;

      switch (type.toLowerCase()) {
        case 'draw':
          title = '✏️ Drawing from $senderName';
          body = 'Your $senderName shared a new drawing with you.';
          break;
        case 'voice':
          title = '🎙️ Voice from $senderName';
          body = 'A new voice fragment is waiting for you.';
          break;
        default:
          title = '📸 Snap from $senderName';
          body = 'Your $senderName sent you a fresh moment.';
      }

      unawaited(PushNotificationService.sendNotificationToPartner(
        title: title,
        body: body,
        type: type.toLowerCase() == 'draw'
            ? 'drawingNote'
            : type.toLowerCase() == 'voice'
                ? 'voiceFragment'
                : 'newSnap',
        extraData: {
          'latestSnapUrl': snapUrl,
          'latestSnapType': type,
          'senderName': senderName,
        },
      ));
    } catch (e) {
      dev.log('Error triggering snap FCM notification client-side: $e');
    }
  }

  Map<String, dynamic> _weeklyEngagementUpdate() {
    final dayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return {
      'weeklyEngagement': {
        dayKey: FieldValue.increment(1),
      },
    };
  }

  void _addCoupleEngagement(
    WriteBatch batch,
    Map<String, dynamic>? userData,
    String uid,
  ) {
    if (userData?['pairStatus'] != 'paired') return;
    final pairId = userData?['pairId'] as String?;
    if (pairId == null) return;

    final dayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    batch.set(
      _firestore.collection('couples').doc(pairId),
      {
        'weeklyEngagement': {
          uid: {
            dayKey: FieldValue.increment(1),
          },
        },
      },
      SetOptions(merge: true),
    );
  }

  String _userCacheKey(String uid) => 'users/$uid';

  String _coupleCacheKey(String pairId) => 'couples/$pairId';
}
