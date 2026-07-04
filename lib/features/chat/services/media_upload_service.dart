import 'dart:io';
import 'package:bea_window_app/features/auth/services/cloudinary_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class MediaUploadService {
  /// Uploads standard image
  Future<String> uploadImage(File file, {required String conversationId, Function(double)? onProgress}) async {
    if (onProgress != null) onProgress(0.1);
    final url = await CloudinaryService.uploadImage(file);
    if (onProgress != null) onProgress(1.0);
    if (url == null) {
      throw Exception('Failed to upload image to Cloudinary');
    }
    return url;
  }

  /// Uploads a generic file (PDF, DOC, ZIP, etc.)
  Future<String> uploadFile(File file, {required String conversationId, Function(double)? onProgress}) async {
    if (onProgress != null) onProgress(0.1);
    final url = await CloudinaryService.uploadFile(file);
    if (onProgress != null) onProgress(1.0);
    if (url == null) {
      throw Exception('Failed to upload file to Cloudinary');
    }
    return url;
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
    } catch (_) {}
    return null;
  }

  /// Coordinates video uploading via Cloudinary
  Future<Map<String, String?>> uploadVideo({
    required File videoFile,
    required String conversationId,
    required Function(double progress) onProgress,
  }) async {
    onProgress(0.1);
    String? thumbnailUrl;
    
    // 1. Generate and upload thumbnail first
    final thumbnailFile = await _generateThumbnail(videoFile.path);
    if (thumbnailFile != null) {
      thumbnailUrl = await CloudinaryService.uploadImage(thumbnailFile);
    }

    onProgress(0.4);

    // 2. Upload video file to Cloudinary
    final videoUrl = await CloudinaryService.uploadVideo(videoFile);
    
    onProgress(1.0);

    if (videoUrl == null) {
      throw Exception('Failed to upload video to Cloudinary');
    }

    return {
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  /// Cancels upload (no-op since standard HTTP uploads are direct)
  Future<void> cancelVideoUpload(String localPath) async {}
}
