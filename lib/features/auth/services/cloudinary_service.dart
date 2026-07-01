import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dpvo4otoj';
  static const String _uploadPreset = 'bae_window_avatars';

  static Future<String?> uploadImage(File imageFile) async {
    return _uploadFile(imageFile, resourceType: 'image');
  }

  /// Cloudinary handles audio files through its video resource endpoint.
  static Future<String?> uploadAudio(File audioFile) async {
    return _uploadFile(audioFile, resourceType: 'video');
  }

  static Future<String?> _uploadFile(
    File file, {
    required String resourceType,
  }) async {
    try {
      dev.log(
        'CloudinaryService: Starting $resourceType upload — ${file.path}',
        name: 'CloudinaryService',
      );

      final uploadUrl =
          'https://api.cloudinary.com/v1_1/$_cloudName/$resourceType/upload';
      final request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final secureUrl = responseData['secure_url'] as String?;

        dev.log(
          'CloudinaryService: Upload successful — $secureUrl',
          name: 'CloudinaryService',
        );

        return secureUrl;
      } else {
        dev.log(
          'CloudinaryService: Upload failed with status ${response.statusCode}\n'
          'Response body: ${response.body}',
          name: 'CloudinaryService',
        );
        return null;
      }
    } catch (e, stack) {
      dev.log(
        'CloudinaryService: Exception during upload — $e',
        error: e,
        stackTrace: stack,
        name: 'CloudinaryService',
      );
      return null;
    }
  }
}
