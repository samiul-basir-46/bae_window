import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/helpers/firestore_cache_service.dart';
import 'package:intl/intl.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';
import '../models/bucket_list_model.dart';

class RealtimeSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreCacheService _cache = FirestoreCacheService.instance;

  // --- Bucket List Sync ---

  Stream<List<BucketListItem>> watchBucketList(String coupleId) {
    final query = _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('bucket_list')
        .orderBy('createdAt', descending: true)
        .limit(50);

    return _cache
        .watchCollectionCacheFirst(
          query: query,
          cacheKey: _bucketCacheKey(coupleId),
          ttl: const Duration(minutes: 10),
        )
        .map((docs) => docs.map((data) {
              final docId = data['id'] as String? ?? '';
              return BucketListItem.fromMap(data, docId);
            }).toList());
  }

  Future<void> addBucketItem(String coupleId, BucketListItem item) async {
    final docRef = _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('bucket_list')
        .doc();
    final itemWithId = item.copyWith(id: docRef.id);
    await docRef.set(itemWithId.toMap());
    await _cache.remove(_bucketCacheKey(coupleId));
  }

  Future<void> updateBucketItem(String coupleId, BucketListItem item) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('bucket_list')
        .doc(item.id)
        .set(item.toMap(), SetOptions(merge: true));
    await _cache.remove(_bucketCacheKey(coupleId));
  }

  Future<void> deleteBucketItem(String coupleId, String itemId) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('bucket_list')
        .doc(itemId)
        .delete();
    await _cache.remove(_bucketCacheKey(coupleId));
  }

  // --- Anniversary Sync ---

  Stream<DateTime?> watchAnniversary(String currentUid) {
    final docRef = _firestore.collection('users').doc(currentUid);

    return _cache
        .watchDocumentCacheFirst(
      ref: docRef,
      cacheKey: 'users/$currentUid',
      ttl: const Duration(minutes: 5),
    )
        .map((data) {
      if (data == null) return null;
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
    final docRef = _firestore.collection('users').doc(partnerUid);

    return _cache
        .watchDocumentCacheFirst(
          ref: docRef,
          cacheKey: 'users/$partnerUid',
          ttl: const Duration(minutes: 5),
        )
        .map((data) => data?['nickname'] as String?);
  }

  // --- Tasks Sync ---

  Stream<List<Map<String, dynamic>>> watchTasks(String coupleId) {
    final query = _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .limit(50);

    return _cache.watchCollectionCacheFirst(
      query: query,
      cacheKey: _tasksCacheKey(coupleId),
      ttl: const Duration(minutes: 5),
    );
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
    await _cache.remove(_tasksCacheKey(coupleId));
  }

  Future<void> updateTask(
      String coupleId, String taskId, Map<String, dynamic> data) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('tasks')
        .doc(taskId)
        .update(data);
    await _cache.remove(_tasksCacheKey(coupleId));
  }

  Future<void> deleteTask(String coupleId, String taskId) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('tasks')
        .doc(taskId)
        .delete();
    await _cache.remove(_tasksCacheKey(coupleId));
  }

  // --- Moments Sync ---

  Stream<List<Map<String, dynamic>>> watchMoments(String coupleId) {
    final query = _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('moments')
        .orderBy('createdAt', descending: true)
        .limit(10);

    return _cache.watchCollectionCacheFirst(
      query: query,
      cacheKey: _momentsCacheKey(coupleId),
      ttl: const Duration(minutes: 5),
    );
  }

  Future<void> addMoment(String coupleId,
      {required String user,
      required String action,
      required String type}) async {
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
    await _cache.remove(_momentsCacheKey(coupleId));
  }

  Future<List<Map<String, dynamic>>> getStories(String coupleId, {bool forceRefresh = false}) {
    final query = _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('stories')
        .orderBy('dateTime', descending: true)
        .limit(50);

    return _cache.getCollection(
      query: query,
      cacheKey: _storiesCacheKey(coupleId),
      ttl: const Duration(minutes: 10), // Cache for 10 minutes to save reads
      forceRefresh: forceRefresh,
    );
  }

  Future<void> addStory({
    required String coupleId,
    required String title,
    required String note,
    required String imageUrl,
    required bool isMilestone,
    required String uploadedByUid,
    required String layoutType,
  }) async {
    final docRef = _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('stories')
        .doc();

    await docRef.set({
      'id': docRef.id,
      'title': title,
      'note': note,
      'imageUrl': imageUrl,
      'isMilestone': isMilestone,
      'uploadedByUid': uploadedByUid,
      'layoutType': layoutType,
      'dateTime': FieldValue.serverTimestamp(),
    });
    await _cache.remove(_storiesCacheKey(coupleId));
  }

  Future<void> updateStoryNote({
    required String coupleId,
    required String storyId,
    required String newNote,
  }) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('stories')
        .doc(storyId)
        .update({
      'note': newNote,
    });
    await _cache.remove(_storiesCacheKey(coupleId));
  }

  Future<void> deleteStory(String coupleId, String storyId) async {
    await _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('stories')
        .doc(storyId)
        .delete();
    await _cache.remove(_storiesCacheKey(coupleId));
  }

  String _bucketCacheKey(String coupleId) => 'couples/$coupleId/bucket_list';

  String _tasksCacheKey(String coupleId) => 'couples/$coupleId/tasks';

  String _momentsCacheKey(String coupleId) => 'couples/$coupleId/moments';

  String _storiesCacheKey(String coupleId) => 'couples/$coupleId/stories';
}
