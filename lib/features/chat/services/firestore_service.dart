import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseFirestore get firestore => _firestore;

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _firestore.collection(path);
  }

  DocumentReference<Map<String, dynamic>> document(String path) {
    return _firestore.doc(path);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(String path) {
    return _firestore.doc(path).get();
  }

  Future<void> setDoc(String path, Map<String, dynamic> data, {bool merge = true}) {
    return _firestore.doc(path).set(data, SetOptions(merge: merge));
  }

  Future<void> updateDoc(String path, Map<String, dynamic> data) {
    return _firestore.doc(path).update(data);
  }

  Future<void> deleteDoc(String path) {
    return _firestore.doc(path).delete();
  }

  Future<DocumentReference<Map<String, dynamic>>> addDoc(String collectionPath, Map<String, dynamic> data) {
    return _firestore.collection(collectionPath).add(data);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchDoc(String path) {
    return _firestore.doc(path).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchCollection(String path, {Query<Map<String, dynamic>> Function(Query<Map<String, dynamic>>)? query}) {
    Query<Map<String, dynamic>> ref = _firestore.collection(path);
    if (query != null) {
      ref = query(ref);
    }
    return ref.snapshots();
  }
}
