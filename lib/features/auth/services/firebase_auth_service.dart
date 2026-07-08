import 'dart:async';
import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/helpers/firestore_cache_service.dart';
import 'package:intl/intl.dart';
import '../../../helpers/notification_service.dart';
import 'firebase_pairing_service.dart';
import 'profile_gate_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreCacheService _cache = FirestoreCacheService.instance;
  final FirebasePairingService _pairingService = FirebasePairingService();

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
    required String gender,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    final updateData = {
      'nickname': nickname,
      'profilePicture': avatarUrl,
      'profileComplete': true,
      'gender': gender,
    };

    await _firestore.collection('users').doc(user.uid).set(
      updateData,
      SetOptions(merge: true),
    );

    // Pre-seed the cache with the merged document instead of just invalidating.
    // This ensures the next getDocument() call returns the updated data
    // even if the server is temporarily unreachable.
    try {
      final freshDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(const GetOptions(source: Source.cache));
      if (freshDoc.exists && freshDoc.data() != null) {
        await _cache.write(_userCacheKey(user.uid), freshDoc.data()!);
      }
    } catch (_) {
      // If cache read fails, just remove. The local flag will protect us.
      await _cache.remove(_userCacheKey(user.uid));
    }

    // Mark as complete via centralized ProfileGateService — the definitive flag
    ProfileGateService.instance.markProfileComplete(user.uid);

    if (avatarUrl.isNotEmpty) {
      await user.updatePhotoURL(avatarUrl);
    }
  }

  /// Generate a unique 6-character invite code
  Future<String> generateInviteCode() => _pairingService.generateInviteCode();

  /// Join with partner's invite code
  Future<void> joinWithCode(String code) => _pairingService.joinWithCode(code);

  /// Skip pairing step
  Future<void> skipPairing() => _pairingService.skipPairing();

  /// Unpair from the partner. Requires reauthentication with current user's password.
  Future<void> unpairCouple(String password) => _pairingService.unpairCouple(password);

  /// Delete user account permanently after reauthentication.
  /// If the user is currently paired, they will be unpaired first.
  Future<void> deleteUserAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    final email = user.email;
    if (email == null) throw Exception('User email is missing.');

    // 1. Reauthenticate
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);

    final uid = user.uid;
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists && userDoc.data() != null) {
      final data = userDoc.data()!;
      final pairStatus = data['pairStatus'] as String? ?? 'none';
      final pairId = data['pairId'] as String?;

      // 2. If paired, unpair them first
      if (pairStatus == 'paired' && pairId != null) {
        await _pairingService.unpairCouple(password);
      }
    }

    // 3. Delete Firestore user document and clear cache
    await _firestore.collection('users').doc(uid).delete();
    await _cache.remove(_userCacheKey(uid));

    // 4. Delete user permanently from Firebase Auth
    await user.delete();
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
  Future<void> updateUserProfile(
    String uid, {
    String? name,
    String? nickname,
    String? relationshipStartDate,
    String? avatarUrl,
    String? gender,
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
    if (gender != null) {
      updates['gender'] = gender;
    }

    ProfileGateService.instance.markProfileComplete(uid);

    if (updates.isNotEmpty) {

      _firestore
          .collection('users')
          .doc(uid)
          .set(updates, SetOptions(merge: true));
      await _cache.remove(_userCacheKey(uid));
    }
  }

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

  Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  Future<Map<String, dynamic>?> getCoupleData(String pairId) =>
      _pairingService.getCoupleData(pairId);

  Stream<DocumentSnapshot<Map<String, dynamic>>> coupleStream(String pairId) =>
      _pairingService.coupleStream(pairId);

  Future<String?> getPartnerUid(String coupleId) =>
      _pairingService.getPartnerUid(coupleId);

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
      /*
      unawaited(PushNotificationService.sendSilentWidgetSyncToPartner(
        extraData: {
          'latestSnapUrl': snapUrl,
          'latestSnapType': type,
          'senderName': senderName,
        },
      ));
      */
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
