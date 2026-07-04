import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_storage/get_storage.dart';

class ChunkUploadService {
  final Dio _dio = Dio();
  final GetStorage _storage = GetStorage();
    static const int chunkSize = 1024 * 1024; 
  
  final Map<String, CancelToken> _cancelTokens = {};
  
  String _getBucketName() {
    return FirebaseStorage.instance.app.options.storageBucket ?? '';
  }

  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    return await user?.getIdToken();
  }

  String _getSessionKey(String localPath) {
    return 'resumable_upload_session_${localPath.hashCode}';
  }

  Future<String> _initiateSession({
    required String storagePath,
    required int totalLength,
    required String mimeType,
  }) async {
    final bucket = _getBucketName();
    final url = 'https://firebasestorage.googleapis.com/v0/b/$bucket/o?uploadType=resumable&name=${Uri.encodeComponent(storagePath)}';
    
    final token = await _getAuthToken();
    final headers = {
      'X-Goog-Upload-Protocol': 'resumable',
      'X-Goog-Upload-Command': 'start',
      'X-Goog-Upload-Header-Content-Length': '$totalLength',
      'X-Goog-Upload-Header-Content-Type': mimeType,
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await _dio.post(
      url,
      options: Options(
        headers: headers,
        validateStatus: (status) => status == 200 || status == 201,
      ),
    );

    final sessionUrl = response.headers.value('Location');
    if (sessionUrl == null) {
      throw Exception('Failed to retrieve resumable upload session URL from headers.');
    }
    return sessionUrl;
  }

  /// Query the server to see how many bytes have been successfully uploaded so far
  Future<int> _queryUploadedOffset(String sessionUrl) async {
    final token = await _getAuthToken();
    final response = await _dio.put(
      sessionUrl,
      options: Options(
        headers: {
          'X-Goog-Upload-Command': 'query',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        validateStatus: (status) => status == 200 || status == 201 || status == 308,
      ),
    );

    final sizeReceived = response.headers.value('X-Goog-Upload-Size-Received');
    if (sizeReceived != null) {
      return int.parse(sizeReceived);
    }
    return 0;
  }

  /// Upload a video file in chunks with resume, cancel, and progress support
  Future<String> uploadVideo({
    required String localPath,
    required String storagePath,
    required Function(double progress) onProgress,
  }) async {
    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Local file does not exist at path: $localPath');
    }

    final totalLength = await file.length();
    const mimeType = 'video/mp4'; // default to mp4 for chat video uploads
    final sessionKey = _getSessionKey(localPath);
    
    String? sessionUrl = _storage.read<String>(sessionKey);
    int offset = 0;

    // Verify sessionUrl still exists and is active, otherwise start a new one
    if (sessionUrl != null) {
      try {
        offset = await _queryUploadedOffset(sessionUrl);
      } catch (_) {
        // Session might have expired or is invalid, reset
        sessionUrl = null;
        offset = 0;
      }
    }

    if (sessionUrl == null) {
      sessionUrl = await _initiateSession(
        storagePath: storagePath,
        totalLength: totalLength,
        mimeType: mimeType,
      );
      _storage.write(sessionKey, sessionUrl);
      offset = 0;
    }

    final cancelToken = CancelToken();
    _cancelTokens[localPath] = cancelToken;

    final raf = await file.open(mode: FileMode.read);
    
    try {
      final token = await _getAuthToken();
      
      while (offset < totalLength) {
        if (cancelToken.isCancelled) {
          throw DioException(
            requestOptions: RequestOptions(path: sessionUrl),
            type: DioExceptionType.cancel,
            message: 'Upload cancelled by user',
          );
        }

        await raf.setPosition(offset);
        final remaining = totalLength - offset;
        final currentChunkSize = remaining < chunkSize ? remaining : chunkSize;
        
        final Uint8List buffer = await raf.read(currentChunkSize);
        final isLastChunk = (offset + currentChunkSize) >= totalLength;

        final command = isLastChunk ? 'upload, finalize' : 'upload';
        
        final response = await _dio.put(
          sessionUrl,
          data: Stream.fromIterable([buffer]),
          cancelToken: cancelToken,
          options: Options(
            headers: {
              'X-Goog-Upload-Command': command,
              'X-Goog-Upload-Offset': '$offset',
              'Content-Length': '$currentChunkSize',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            validateStatus: (status) => status == 200 || status == 201 || status == 308,
          ),
          onSendProgress: (sent, total) {
            final chunkProgress = sent / total;
            final overallProgress = (offset + (chunkProgress * currentChunkSize)) / totalLength;
            onProgress(overallProgress);
          },
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Final chunk upload completed or finalization succeeded
          offset = totalLength;
        } else if (response.statusCode == 308) {
          // Chunk accepted, increment offset and loop
          offset += currentChunkSize;
        } else {
          throw Exception('Chunk upload failed with status: ${response.statusCode}');
        }
        
        onProgress(offset / totalLength);
      }
      
      // Cleanup session cache upon success
      _storage.remove(sessionKey);
      _cancelTokens.remove(localPath);

      // Get the absolute Firebase Storage download URL
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      return await storageRef.getDownloadURL();
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // Upload was cancelled, keep session so it can be resumed
        rethrow;
      }
      // For general failures, keep session so user can retry, just rethrow
      rethrow;
    } finally {
      await raf.close();
    }
  }

  /// Cancel an ongoing upload
  Future<void> cancelUpload(String localPath) async {
    final cancelToken = _cancelTokens[localPath];
    if (cancelToken != null && !cancelToken.isCancelled) {
      cancelToken.cancel('Upload cancelled');
    }
    
    // We can also notify the server to discard the session data
    final sessionKey = _getSessionKey(localPath);
    final sessionUrl = _storage.read<String>(sessionKey);
    if (sessionUrl != null) {
      try {
        final token = await _getAuthToken();
        await _dio.put(
          sessionUrl,
          options: Options(
            headers: {
              'X-Goog-Upload-Command': 'cancel',
              if (token != null) 'Authorization': 'Bearer $token',
            },
          ),
        );
      } catch (_) {}
      _storage.remove(sessionKey);
    }
    _cancelTokens.remove(localPath);
  }
}
