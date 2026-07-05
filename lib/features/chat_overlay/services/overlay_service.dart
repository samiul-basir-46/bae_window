import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayService {
  Future<void> showChatHead({
    String notificationTitle = 'Bae Window',
    String notificationMessage = 'Chat head is active',
  }) async {
    final isGranted = await FlutterOverlayWindow.isPermissionGranted();
    if (!isGranted) return;

    if (await FlutterOverlayWindow.isActive()) return;

    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: notificationTitle,
      overlayContent: notificationMessage,
      flag: OverlayFlag.defaultFlag,
      alignment: OverlayAlignment.centerLeft,
      visibility: NotificationVisibility.visibilityPrivate,
      positionGravity: PositionGravity.none,
      height: WindowSize.matchParent,
      width: WindowSize.matchParent,
    );
  }

  Future<void> closeChatHead() async {
    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
    }
  }

  void updateOverlayData(Map<String, dynamic> data) {
    FlutterOverlayWindow.shareData(data);
  }
}
