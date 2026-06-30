import 'dart:io';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class WidgetHelper {
  static const String _androidWidgetName = 'BaeWindowWidgetProvider';

  static Future<void> updateWidget({
    required bool isPaired,
    required String? partnerName,
    required int? daysTogether,
    required String? latestSnapUrl,
  }) async {
    // 1. Determine Title & Status text
    final String title = isPaired ? "You & ${partnerName ?? 'Bae'}" : "Bae Window";
    final String status = isPaired
        ? (daysTogether != null
            ? "$daysTogether Days Together ❤️"
            : "Set Anniversary Date 📅")
        : "Solo Mode ✦ Invite your partner";

    // Write texts to shared preferences
    await HomeWidget.saveWidgetData<String>('title', title);
    await HomeWidget.saveWidgetData<String>('status', status);

    // 2. Download and save the snap image locally if available
    if (latestSnapUrl != null && latestSnapUrl.isNotEmpty) {
      try {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/latest_snap.png';
        
        final response = await http.get(Uri.parse(latestSnapUrl));
        if (response.statusCode == 200) {
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);
          
          // Write local file path to shared preferences
          await HomeWidget.saveWidgetData<String>('imagePath', filePath);
        }
      } catch (e) {
        // Fallback or ignore error
      }
    } else {
      // Clear image path if none exists
      await HomeWidget.saveWidgetData<String>('imagePath', null);
    }

    // 3. Trigger Widget Update on Android
    await HomeWidget.updateWidget(
      name: _androidWidgetName,
      androidName: _androidWidgetName,
    );
  }
}
