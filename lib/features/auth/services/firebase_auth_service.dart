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
    });
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

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));
    }
  }
}
