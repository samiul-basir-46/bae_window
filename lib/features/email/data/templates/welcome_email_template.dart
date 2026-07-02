String baeWindowWelcomeEmailHtml({required String userName}) {
  return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Welcome to Bae Window</title>
</head>
<body style="margin:0; padding:0; background-color:#1a0f1a; font-family:'Helvetica Neue', Arial, sans-serif;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="background-color:#1a0f1a; padding:40px 0;">
    <tr>
      <td align="center">
        <table role="presentation" width="480" cellpadding="0" cellspacing="0" style="background: linear-gradient(135deg, #2b1220 0%, #4a1942 50%, #2b1220 100%); border-radius:20px; overflow:hidden; box-shadow:0 10px 40px rgba(233,64,143,0.25);">

          <!-- Header -->
          <tr>
            <td style="padding:40px 30px 20px 30px;" align="center">
              <div style="font-size:40px; margin-bottom:10px;">💕</div>
              <h1 style="margin:0; font-size:26px; color:#ffffff; font-weight:700; letter-spacing:0.5px;">
                Bae Window
              </h1>
              <p style="margin:8px 0 0 0; color:#f4a6c8; font-size:14px;">
                একটা জানালা, দুটো হৃদয়
              </p>
            </td>
          </tr>

          <!-- Divider -->
          <tr>
            <td style="padding:0 30px;">
              <div style="height:1px; background: linear-gradient(90deg, transparent, #e9408f, transparent);"></div>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:30px 35px;">
              <p style="color:#ffffff; font-size:18px; margin:0 0 16px 0;">
                হ্যালো, <strong style="color:#f4a6c8;">$userName</strong> 👋
              </p>
              <p style="color:#d9c2d4; font-size:15px; line-height:1.7; margin:0 0 24px 0;">
                Bae Window পরিবারে তোমাকে স্বাগতম! এখন থেকে তুমি তোমার প্রিয় মানুষের সাথে
                প্রতিদিনের মুহূর্ত, স্মৃতি আর ভালোবাসা শেয়ার করতে পারবে এক জায়গায়।
              </p>

              <!-- CTA Button -->
              <table role="presentation" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td align="center" style="padding:10px 0 24px 0;">
                    <a href="#" style="display:inline-block; background: linear-gradient(135deg, #e9408f, #ff6fa5); color:#ffffff; text-decoration:none; font-size:15px; font-weight:600; padding:14px 36px; border-radius:30px; box-shadow:0 6px 20px rgba(233,64,143,0.4);">
                      অ্যাপ খুলি চলো →
                    </a>
                  </td>
                </tr>
              </table>

              <p style="color:#a98ba2; font-size:13px; line-height:1.6; margin:0;">
                যদি এই email তোমার জন্য না হয়ে থাকে, নিশ্চিন্তে ignore করে দিতে পারো।
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding:20px 30px 30px 30px; border-top:1px solid rgba(255,255,255,0.08);" align="center">
              <p style="color:#7a5a72; font-size:12px; margin:0;">
                © 2026 Bae Window. Made with 💗 for couples.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
}
