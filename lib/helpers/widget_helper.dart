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
    String? latestImageUrl,
    String? latestDrawingUrl,
    String? latestVoiceUrl,
    String? avatarLetter,
    String? partnerMoodEmoji,
    String? partnerMoodText,
    int? partnerBatteryLevel,
  }) async {
    final String status = isPaired
        ? (daysTogether != null
            ? "$daysTogether Days Together ❤️"
            : "Set Anniversary Date 📅")
        : "Solo Mode";

    final String senderName = isPaired ? "from ${partnerName ?? 'Bae'}" : "";

    final normalizedType = latestSnapType?.toLowerCase();
    final String footerDescription;
    if (!isPaired) {
      footerDescription = "Connect with partner";
    } else if (latestSnapUrl == null || latestSnapUrl.isEmpty) {
      footerDescription = "Awaiting first share";
    } else if (normalizedType == 'draw') {
      footerDescription = "${partnerName ?? 'Bae'} sent a drawing";
    } else if (normalizedType == 'voice') {
      footerDescription = "${partnerName ?? 'Bae'} sent a voice message";
    } else {
      footerDescription = "${partnerName ?? 'Bae'} sent a photo";
    }

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
    await HomeWidget.saveWidgetData<String>(
      'partnerMoodEmoji',
      partnerMoodEmoji ?? '',
    );
    await HomeWidget.saveWidgetData<String>(
      'partnerMoodText',
      partnerMoodText ?? '',
    );
    await HomeWidget.saveWidgetData<int>(
      'partnerBatteryLevel',
      partnerBatteryLevel ?? -1,
    );

    if (latestSnapType != null && latestSnapType.isNotEmpty) {
      await HomeWidget.saveWidgetData<String>('badgeText', latestSnapType);
    } else {
      await HomeWidget.saveWidgetData<String>('badgeText', null);
    }

    await HomeWidget.saveWidgetData<String>(
        'dockPartnerStatus', dockPartnerStatus);
    await HomeWidget.saveWidgetData<String>('dockSubtitle', dockSubtitle);

    final resolvedImageUrl = latestImageUrl ??
        (normalizedType != 'draw' && normalizedType != 'voice'
            ? latestSnapUrl
            : null);
    final resolvedDrawingUrl =
        latestDrawingUrl ?? (normalizedType == 'draw' ? latestSnapUrl : null);

    await _cacheWidgetImage(
      url: resolvedImageUrl,
      fileName: 'latest_image.png',
      preferenceKey: 'imagePath',
    );
    await _cacheWidgetImage(
      url: resolvedDrawingUrl,
      fileName: 'latest_drawing.png',
      preferenceKey: 'drawingPath',
    );
    await HomeWidget.saveWidgetData<String>(
      'voiceUrl',
      latestVoiceUrl?.isNotEmpty == true ? latestVoiceUrl : null,
    );

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

  static Future<void> _cacheWidgetImage({
    required String? url,
    required String fileName,
    required String preferenceKey,
  }) async {
    if (url == null || url.isEmpty) {
      await HomeWidget.saveWidgetData<String>(preferenceKey, null);
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes, flush: true);
        await HomeWidget.saveWidgetData<String>(preferenceKey, filePath);
      } else {
        await HomeWidget.saveWidgetData<String>(preferenceKey, null);
      }
    } catch (_) {
      await HomeWidget.saveWidgetData<String>(preferenceKey, null);
    }
  }
}
