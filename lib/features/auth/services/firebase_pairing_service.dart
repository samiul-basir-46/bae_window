import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/helpers/firestore_cache_service.dart';
import 'package:bea_window_app/features/auth/services/profile_gate_service.dart';

class FirebasePairingService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreCacheService _cache = FirestoreCacheService.instance;

  String _userCacheKey(String uid) => 'users/$uid';
  String _coupleCacheKey(String pairId) => 'couples/$pairId';

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

    // Mark pair status locally for both users
    ProfileGateService.instance.markPairStatus(user.uid, 'paired');
  }

  /// Skip pairing step
  Future<void> skipPairing() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    await _firestore.collection('users').doc(user.uid).set({
      'pairStatus': 'unpaired',
    }, SetOptions(merge: true));
    await _cache.remove(_userCacheKey(user.uid));

    // Mark pair status locally so next app launch goes to Home, not Pairing
    ProfileGateService.instance.markPairStatus(user.uid, 'unpaired');
  }

  /// Unpair from the partner. Requires reauthentication with current user's password.
  Future<void> unpairCouple(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw Exception('No authenticated user found.');
    }

    // 1. Reauthenticate
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: password,
    );
    await user.reauthenticateWithCredential(credential);

    // 2. Retrieve current user's pairing details
    final userRef = _firestore.collection('users').doc(user.uid);
    final userSnapshot = await userRef.get();
    if (!userSnapshot.exists) {
      throw Exception('User profile not found.');
    }

    final userData = userSnapshot.data();
    if (userData == null || userData['pairStatus'] != 'paired') {
      throw Exception('User is not paired.');
    }

    final pairId = userData['pairId'] as String?;
    if (pairId == null || pairId.isEmpty) {
      throw Exception('Pair ID not found.');
    }

    // 3. Resolve partner UID
    final partnerUid = await getPartnerUid(pairId);

    // 4. Update Firestore documents using a batch
    final batch = _firestore.batch();

    // Reset current user
    batch.set(userRef, {
      'pairStatus': 'unpaired',
      'pairId': FieldValue.delete(),
    }, SetOptions(merge: true));

    // Reset partner user if found
    if (partnerUid != null && partnerUid.isNotEmpty) {
      final partnerRef = _firestore.collection('users').doc(partnerUid);
      batch.set(partnerRef, {
        'pairStatus': 'unpaired',
        'pairId': FieldValue.delete(),
      }, SetOptions(merge: true));
    }

    // Update couple status to inactive/unpaired
    final coupleRef = _firestore.collection('couples').doc(pairId);
    batch.update(coupleRef, {'status': 'unpaired'});

    await batch.commit();

    // 5. Clear caches
    await _cache.remove(_userCacheKey(user.uid));
    if (partnerUid != null && partnerUid.isNotEmpty) {
      await _cache.remove(_userCacheKey(partnerUid));
    }
    await _cache.remove(_coupleCacheKey(pairId));
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
}
