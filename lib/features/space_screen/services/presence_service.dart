import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserPresence(String uid, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'isOnline': isOnline,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Stream<bool> watchPartnerPresence(String partnerUid) {
    return _firestore
        .collection('users')
        .doc(partnerUid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return false;
      return snapshot.data()!['isOnline'] as bool? ?? false;
    });
  }
}
