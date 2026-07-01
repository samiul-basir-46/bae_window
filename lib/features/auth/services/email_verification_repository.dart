import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import 'brevo_email_service.dart';

class EmailVerificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BrevoEmailService _brevoService = BrevoEmailService();

  // Helper to generate a secure random 32-char hex token
  String _generateSecureToken() {
    final Random random = Random.secure();
    final List<int> values = List<int>.generate(16, (i) => random.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> sendVerification({
    required String uid,
    required String email,
    required String name,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final snapshot = await userRef.get();
      final data = snapshot.data();

      // Rate limit check: must wait at least 60 seconds
      if (data != null && data['lastSentAt'] != null) {
        final lastSent = (data['lastSentAt'] as Timestamp).toDate();
        final difference = DateTime.now().difference(lastSent).inSeconds;
        if (difference < 60) {
          throw Exception("Please wait ${60 - difference} seconds before resending.");
        }
      }

      final token = _generateSecureToken();
      final expiry = DateTime.now().add(const Duration(minutes: 30));

      // Save token + expiry + lastSentAt in user document
      await userRef.set({
        'verificationToken': token,
        'tokenExpiry': Timestamp.fromDate(expiry),
        'lastSentAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final verificationLink = "baewindow://verify?token=$token&uid=$uid";

      final success = await _brevoService.sendVerificationEmail(
        recipientEmail: email,
        recipientName: name,
        verificationLink: verificationLink,
      );

      if (!success) {
        throw Exception("Failed to deliver email through Brevo.");
      }
    } catch (e, stack) {
      dev.log("Error sending verification: $e", stackTrace: stack, name: "EmailVerificationRepository");
      rethrow;
    }
  }

  Future<bool> verifyToken({
    required String uid,
    required String token,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final snapshot = await userRef.get();
      if (!snapshot.exists || snapshot.data() == null) {
        return false;
      }

      final data = snapshot.data()!;
      final savedToken = data['verificationToken'] as String?;
      final expiry = data['tokenExpiry'] as Timestamp?;

      if (savedToken == null || expiry == null || savedToken != token) {
        return false;
      }

      if (DateTime.now().isAfter(expiry.toDate())) {
        return false; // Token expired
      }

      // Mark user as verified and clean verification tokens
      await userRef.set({
        'isEmailVerified': true,
        'verificationToken': FieldValue.delete(),
        'tokenExpiry': FieldValue.delete(),
      }, SetOptions(merge: true));

      return true;
    } catch (e, stack) {
      dev.log("Error verifying token: $e", stackTrace: stack, name: "EmailVerificationRepository");
      return false;
    }
  }

  Future<bool> checkVerificationStatus(String uid) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      if (!snapshot.exists || snapshot.data() == null) {
        return false;
      }
      return snapshot.data()!['isEmailVerified'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }
}
