import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';
import '../models/bucket_list_model.dart';

class RealtimeSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Bucket List Sync ---

  Stream<List<BucketListItem>> watchBucketList(String coupleId) {
    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('bucket_list')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return BucketListItem.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<void> addBucketItem(String coupleId, BucketListItem item) async {
    final docRef = _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('bucket_list')
        .doc();
    final itemWithId = item.copyWith(id: docRef.id);
    await docRef.set(itemWithId.toMap());
  }

  Future<void> updateBucketItem(String coupleId, BucketListItem item) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('bucket_list')
        .doc(item.id)
        .set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteBucketItem(String coupleId, String itemId) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('bucket_list')
        .doc(itemId)
        .delete();
  }

  // --- Anniversary Sync ---

  Stream<DateTime?> watchAnniversary(String currentUid) {
    return _firestore
        .collection('users')
        .doc(currentUid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final data = snapshot.data()!;
      final dateStr = data['relationshipStartDate'] as String?;
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        return DateFormat('MMM d, yyyy').parse(dateStr);
      } catch (_) {
        return DateTime.tryParse(dateStr);
      }
    });
  }

  Future<void> updateAnniversary(String currentUid, DateTime date) async {
    final dateStr = DateFormat('MMM d, yyyy').format(date);
    await FirebaseAuthService().updateUserProfile(
      currentUid,
      relationshipStartDate: dateStr,
    );
  }

  // --- Partner Nickname Sync ---

  Stream<String?> watchPartnerNickname(String partnerUid) {
    return _firestore
        .collection('users')
        .doc(partnerUid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return snapshot.data()!['nickname'] as String?;
    });
  }

  // --- Tasks Sync ---

  Stream<List<Map<String, dynamic>>> watchTasks(String coupleId) {
    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> addTask({
    required String coupleId,
    required String title,
    required String creatorUid,
    required String creatorName,
    required String assignedToUid,
    required String assignedToName,
    required String status,
  }) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('tasks')
        .add({
      'title': title,
      'creatorUid': creatorUid,
      'creatorName': creatorName,
      'assignedToUid': assignedToUid,
      'assignedToName': assignedToName,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateTask(String coupleId, String taskId, Map<String, dynamic> data) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('tasks')
        .doc(taskId)
        .update(data);
  }

  Future<void> deleteTask(String coupleId, String taskId) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // --- Moments Sync ---

  Stream<List<Map<String, dynamic>>> watchMoments(String coupleId) {
    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('moments')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return doc.data();
      }).toList();
    });
  }

  Future<void> addMoment(String coupleId, {required String user, required String action, required String type}) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('moments')
        .add({
      'user': user,
      'action': action,
      'type': type,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
