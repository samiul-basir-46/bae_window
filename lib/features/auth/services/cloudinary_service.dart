import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:http/http.dart' as http;

/// Service to upload images to Cloudinary using unsigned upload preset.
/// No API key/secret is required on the client side.
class CloudinaryService {
  static const String _cloudName = 'dpvo4otoj';
  static const String _uploadPreset = 'bae_window_avatars';
  static const String _uploadUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload';

  /// Uploads an image file to Cloudinary.
  ///
  /// Returns the [secure_url] on success, or `null` on failure.
  static Future<String?> uploadImage(File imageFile) async {
    try {
      dev.log(
        'CloudinaryService: Starting image upload — ${imageFile.path}',
        name: 'CloudinaryService',
      );

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // Add the upload preset (unsigned mode — no API key needed)
      request.fields['upload_preset'] = _uploadPreset;

      // Attach the image file
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
