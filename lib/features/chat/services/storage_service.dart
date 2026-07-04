import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  FirebaseStorage get storage => _storage;

  /// Uploads a file to Firebase Storage and returns the download URL
  /// [path] is the destination path inside the storage bucket
  /// [file] is the local file to upload
  /// [onProgress] callback with progress fraction (0.0 to 1.0)
  UploadTask uploadFile({
    required String path,
    required File file,
    SettableMetadata? metadata,
  }) {
    final ref = _storage.ref().child(path);
    return ref.putFile(file, metadata);
  }

  /// Helper to get download URL
  Future<String> getDownloadUrl(String path) {
    return _storage.ref().child(path).getDownloadURL();
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String path) {
    return _storage.ref().child(path).delete();
  }
}
