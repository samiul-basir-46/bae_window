import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:email_otp/email_otp.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final EmailOTP _emailOtp = EmailOTP();

  /// Send OTP code to user's email
  Future<bool> sendOtp(String email) async {
    _emailOtp.setConfig(
      appEmail: "auth@beawindow.com",
      appName: "Bea Window",
      userEmail: email,
      otpLength: 6,
      otpType: OTPType.digitsOnly,
    );
    return await _emailOtp.sendOTP();
  }

  /// Verify OTP code entered by user
  Future<bool> verifyOtp(String otp) async {
    return await _emailOtp.verifyOTP(otp: otp);
  }

  /// Send email verification link
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
    }
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
      'bio': 'Hey there! I am using Bea Window.',
      'profilePicture': '',
      'profileComplete': false,
      'pairStatus': 'none',
    }, SetOptions(merge: true));
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
      code = List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
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

    return code;
  }

  /// Join with partner's invite code
  Future<void> joinWithCode(String code) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    final codeDoc = await _firestore.collection('pairing_codes').doc(code).get();
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
  }

  /// Skip pairing step
  Future<void> skipPairing() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No authenticated user found.');

    await _firestore.collection('users').doc(user.uid).set({
      'pairStatus': 'unpaired',
    }, SetOptions(merge: true));
  }

  /// Retrieve user profile details from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
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
      updates['relationshipStartDate'] = relationshipStartDate;
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
      _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));
    }
  }
}