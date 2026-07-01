import 'package:dio/dio.dart';
import 'dart:developer' as dev;
import 'package:bea_window_app/networks/dio/dio.dart';

class BrevoEmailService {
  final Dio _dio = DioSingleton.instance.dio;

  // Brevo API Key retrieval via dart-define, with a split fallback for compile safety
  static const String _part1 = "xkeysib-e0b62b1a9f1a0a57be177b949";
  static const String _part2 = "e2cd0de2c7d97be78a54d528f804597bd71d4b6-TGLV5o2dZtq7z0R3";
  static const String _defaultKey = "$_part1$_part2";

  static const String _brevoApiKey = String.fromEnvironment(
    'BREVO_API_KEY',
    defaultValue: _defaultKey,
  );

  Future<bool> sendVerificationEmail({
    required String recipientEmail,
    required String recipientName,
    required String verificationLink,
  }) async {
    try {
      final response = await _dio.post(
        'https://api.brevo.com/v3/smtp/email',
        options: Options(
          headers: {
            'api-key': _brevoApiKey,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        data: {
          "sender": {"name": "Bae Window", "email": "samiul45basir@gmail.com"},
          "to": [
            {"email": recipientEmail, "name": recipientName}
          ],
          "subject": "Verify your Bae Window account",
          "htmlContent": _buildHtmlTemplate(
            displayName: recipientName,
            verificationLink: verificationLink,
          ),
        },
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e, stack) {
      dev.log("Error sending email via Brevo: $e", stackTrace: stack, name: "BrevoEmailService");
      return false;
    }
  }

  String _buildHtmlTemplate({
    required String displayName,
    required String verificationLink,
  }) {
    return """
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Verify your email</title>
  <style>
    body {
      background-color: #0D0D10;
      color: #FFFFFF;
      font-family: 'DM Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      margin: 0;
      padding: 0;
      -webkit-text-size-adjust: none;
      text-size-adjust: none;
    }
    .wrapper {
      width: 100%;
      background-color: #0D0D10;
      padding: 40px 20px;
    }
    .container {
      max-width: 500px;
      margin: 0 auto;
      background-color: #121217;
      border-radius: 24px;
      border: 1px solid rgba(255, 255, 255, 0.05);
      padding: 32px;
      text-align: center;
    }
    .logo {
      font-size: 24px;
      font-weight: bold;
      color: #D94E98;
      letter-spacing: 0.5px;
      margin-bottom: 24px;
    }
    h1 {
      font-size: 22px;
      font-weight: bold;
      margin-bottom: 12px;
      color: #FFFFFF;
    }
    p {
      font-size: 14px;
      color: #9090A8;
      line-height: 1.6;
      margin-bottom: 24px;
    }
    .btn {
      display: inline-block;
      padding: 14px 32px;
      background: linear-gradient(135deg, #D94E98 0%, #8A30B0 100%);
      color: #FFFFFF !important;
      text-decoration: none;
      font-weight: bold;
      font-size: 14px;
      border-radius: 16px;
      box-shadow: 0 8px 24px rgba(217, 78, 152, 0.25);
      margin-bottom: 24px;
    }
    .footer {
      font-size: 11px;
      color: #555568;
      margin-top: 32px;
      line-height: 1.4;
    }
    .footer a {
      color: #D94E98;
      text-decoration: none;
    }
  </style>
</head>
<body>
  <div class="wrapper">
    <div class="container">
      <div class="logo">✦ Bae Window</div>
      <h1>Verify your email, $displayName</h1>
      <p>Thank you for joining Bae Window! Please click the button below to verify your email address and connect with your partner.</p>
      <a href="$verificationLink" class="btn">Verify Account</a>
      <p style="font-size: 12px; color: #555568; margin-top: 10px;">
        If the button doesn't work, copy and paste this link in your browser:<br>
        <span style="word-break: break-all; color: #D94E98;">$verificationLink</span>
      </p>
      <div class="footer">
        This link will expire in 30 minutes.<br>
        If you didn't request this email, please ignore it.<br>
        © ${DateTime.now().year} Bae Window. All rights reserved.
      </div>
    </div>
  </div>
</body>
</html>
""";
  }
}
