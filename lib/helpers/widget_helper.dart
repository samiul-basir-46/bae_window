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
    String? latestSnapType,
    String? avatarLetter,
  }) async {
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

    final String timestamp = DateFormat('h:mm a').format(DateTime.now());

    final String avatar = avatarLetter ??
        (partnerName != null && partnerName.isNotEmpty
            ? partnerName[0].toUpperCase()
            : "B");

    final String dockPartnerStatus =
        isPaired ? "${partnerName ?? 'Bae'}'s Phone" : "Bae Window";
    final String dockSubtitle =
        isPaired ? "Tap to send something ✨" : "Pair with your partner first";

    await HomeWidget.saveWidgetData<bool>('isPaired', isPaired);
    await HomeWidget.saveWidgetData<String>('status', status);
    await HomeWidget.saveWidgetData<String>('senderName', senderName);
    await HomeWidget.saveWidgetData<String>(
        'footerDescription', footerDescription);
    await HomeWidget.saveWidgetData<String>('timestamp', timestamp);
    await HomeWidget.saveWidgetData<String>('avatarLetter', avatar);

    if (latestSnapType != null && latestSnapType.isNotEmpty) {
      await HomeWidget.saveWidgetData<String>('badgeText', latestSnapType);
    } else {
      await HomeWidget.saveWidgetData<String>('badgeText', null);
    }

    await HomeWidget.saveWidgetData<String>(
        'dockPartnerStatus', dockPartnerStatus);
    await HomeWidget.saveWidgetData<String>('dockSubtitle', dockSubtitle);

    // Save snap image using app's local storage so Widget can read it
    if (latestSnapUrl != null && latestSnapUrl.isNotEmpty) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/latest_snap.png';

        // ignore: avoid_print
        print('WidgetHelper: downloading snap from $latestSnapUrl');
        // ignore: avoid_print
        print('WidgetHelper: saving to $filePath');

        final response = await http
            .get(Uri.parse(latestSnapUrl))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes, flush: true);

          // ignore: avoid_print
          print(
              'WidgetHelper: snap saved, size=${response.bodyBytes.length} bytes');

          await HomeWidget.saveWidgetData<String>('imagePath', filePath);
        } else {
          // ignore: avoid_print
          print(
              'WidgetHelper: snap download failed, status ${response.statusCode}, bodyLen=${response.bodyBytes.length}');
          await HomeWidget.saveWidgetData<String>('imagePath', null);
        }
      } catch (e) {
        // ignore: avoid_print
        print('WidgetHelper: error downloading/saving snap image — $e');
        await HomeWidget.saveWidgetData<String>('imagePath', null);
      }
    } else {
      await HomeWidget.saveWidgetData<String>('imagePath', null);
    }

    // Trigger Widget Updates on Android
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
