import 'dart:io';
import 'package:bea_window_app/features/chat/services/chunk_upload_service.dart';
import 'package:bea_window_app/features/chat/services/storage_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path/path.dart' as p;

class MediaUploadService {
  final StorageService _storageService = StorageService();
  final ChunkUploadService _chunkUploadService = ChunkUploadService();

  /// Uploads standard image
  Future<String> uploadImage(File file, {required String conversationId, Function(double)? onProgress}) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
    final storagePath = 'chats/$conversationId/images/$fileName';
    
    final uploadTask = _storageService.uploadFile(path: storagePath, file: file);
    
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          onProgress(event.bytesTransferred / event.totalBytes);
        }
      });
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Uploads a generic file (PDF, DOC, ZIP, etc.)
  Future<String> uploadFile(File file, {required String conversationId, Function(double)? onProgress}) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
    final storagePath = 'chats/$conversationId/files/$fileName';

    final uploadTask = _storageService.uploadFile(path: storagePath, file: file);
    
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((event) {
        if (event.totalBytes > 0) {
          onProgress(event.bytesTransferred / event.totalBytes);
        }
      });
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Generates a video thumbnail locally
  Future<File?> _generateThumbnail(String videoPath) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: tempDir.path,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 150,
        quality: 60,
      );
      if (thumbnailPath != null) {
        return File(thumbnailPath);
      }
    } catch (_) {
      // Return null on failure (e.g. platform/simulator constraints) to prevent crashing the flow
    }
    return null;
  }

  /// Coordinates chunk-based video uploading
  /// Exposes detailed upload progress callback.
  /// Returns a Map containing {'videoUrl': ..., 'thumbnailUrl': ...}
  Future<Map<String, String?>> uploadVideo({
    required File videoFile,
    required String conversationId,
    required Function(double progress) onProgress,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final baseName = p.basename(videoFile.path);
    final videoStoragePath = 'chats/$conversationId/videos/${timestamp}_$baseName';
    final thumbnailStoragePath = 'chats/$conversationId/thumbnails/${timestamp}_${p.setExtension(baseName, '.jpg')}';

    String? thumbnailUrl;
    
    // 1. Generate and upload thumbnail first (minor step, quick upload)
    final thumbnailFile = await _generateThumbnail(videoFile.path);
    if (thumbnailFile != null) {
      try {
        final thumbUpload = await _storageService.uploadFile(
          path: thumbnailStoragePath,
          file: thumbnailFile,
        );
        thumbnailUrl = await thumbUpload.ref.getDownloadURL();
      } catch (_) {
        // Safe fallback: continue video upload even if thumbnail upload fails
      }
    }

    // 2. Perform chunked upload for the large video file
    final videoUrl = await _chunkUploadService.uploadVideo(
      localPath: videoFile.path,
      storagePath: videoStoragePath,
      onProgress: onProgress,
    );

    return {
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  /// Cancels an ongoing chunked upload
  Future<void> cancelVideoUpload(String localPath) {
    return _chunkUploadService.cancelUpload(localPath);
  }
}
