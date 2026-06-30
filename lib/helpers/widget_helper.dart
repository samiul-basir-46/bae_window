import 'dart:io';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class WidgetHelper {
  static const String _androidWidgetName = 'BaeWindowWidgetProvider';
  static const String _androidDockWidgetName = 'BaeWindowWidgetDockProvider';

  static Future<void> updateWidget({
    required bool isPaired,
    required String? partnerName,
    required int? daysTogether,
    required String? latestSnapUrl,
    String? latestSnapType, // "Image" or "Draw" etc.
    String? avatarLetter,
  }) async {
    // 1. Determine status text — must match keys read by BaeWindowWidgetProvider.kt
    final String status = isPaired
        ? (daysTogether != null
            ? "$daysTogether Days Together ❤️"
            : "Set Anniversary Date 📅")
        : "Solo Mode";

    final String senderName = isPaired ? "from ${partnerName ?? 'Bae'}" : "";

    final String footerDescription = isPaired
        ? (latestSnapUrl != null && latestSnapUrl.isNotEmpty
            ? "${partnerName ?? 'Bae'} sent a photo"
            : "Awaiting first snap")
        : "Connect with partner";

    // Timestamp
    final String timestamp = DateFormat('h:mm a').format(DateTime.now());

    // Avatar letter — first letter of partner name
    final String avatar = avatarLetter ??
        (partnerName != null && partnerName.isNotEmpty
            ? partnerName[0].toUpperCase()
            : "B");

    // Dock widget data
    final String dockPartnerStatus =
        isPaired ? "${partnerName ?? 'Bae'}'s Phone" : "Bae Window";
    final String dockSubtitle =
        isPaired ? "Tap to send something ✨" : "Pair with your partner first";

    // --- Write all keys that BaeWindowWidgetProvider.kt reads ---
    await HomeWidget.saveWidgetData<bool>('isPaired', isPaired);
    await HomeWidget.saveWidgetData<String>('status', status);
    await HomeWidget.saveWidgetData<String>('senderName', senderName);
    await HomeWidget.saveWidgetData<String>('footerDescription', footerDescription);
    await HomeWidget.saveWidgetData<String>('timestamp', timestamp);
    await HomeWidget.saveWidgetData<String>('avatarLetter', avatar);

    if (latestSnapType != null && latestSnapType.isNotEmpty) {
      await HomeWidget.saveWidgetData<String>('badgeText', latestSnapType);
    } else {
      await HomeWidget.saveWidgetData<String>('badgeText', null);
    }

    // --- Write keys that BaeWindowWidgetDockProvider.kt reads ---
    await HomeWidget.saveWidgetData<String>('dockPartnerStatus', dockPartnerStatus);
    await HomeWidget.saveWidgetData<String>('dockSubtitle', dockSubtitle);

    // 2. Save snap image using public application directory so Widget can read it
    if (latestSnapUrl != null && latestSnapUrl.isNotEmpty) {
      try {
        final directory = await getApplicationSupportDirectory();
        final filePath = '${directory.path}/latest_snap.png';

        final response = await http.get(Uri.parse(latestSnapUrl));
        if (response.statusCode == 200) {
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          // Ensure it's readable by other processes (Widget)
          await Process.run('chmod', ['644', filePath]);

          await HomeWidget.saveWidgetData<String>('imagePath', filePath);
        }
      } catch (_) {
        await HomeWidget.saveWidgetData<String>('imagePath', null);
      }
    } else {
      await HomeWidget.saveWidgetData<String>('imagePath', null);
    }

    // 3. Trigger Widget Updates on Android
    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
    );
    await HomeWidget.updateWidget(
      name: _androidDockWidgetName,
      androidName: _androidDockWidgetName,
    );
  }
}
