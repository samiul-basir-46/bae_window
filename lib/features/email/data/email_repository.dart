import 'dart:developer';
import 'package:dio/dio.dart';

class EmailRepository {
  final Dio _dio;

  EmailRepository(this._dio);

  static const String _emailEndpoint =
      'https://hello-world.samiul45basir.workers.dev';

  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlContent,
    String name = '',
  }) async {
    try {
      final response = await _dio.post(
        _emailEndpoint,
        data: {
          'to': to,
          'name': name,
          'subject': subject,
          'html': htmlContent,
        },
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      log('Email response: ${response.data}');

      // Resend returns an "id" field on success
      return response.statusCode == 200 && response.data['id'] != null;
    } catch (e) {
      log('Email send error: $e');
      return false;
    }
  }
}
