import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String _cloudName = 'dpvo4otoj';
  static const String _uploadPreset = 'bae_window_avatars';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  static Future<String?> uploadImage(File imageFile) async {
    try {
      dev.log(
        'CloudinaryService: Starting image upload — ${imageFile.path}',
        name: 'CloudinaryService',
      );

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = _uploadPreset;
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
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
