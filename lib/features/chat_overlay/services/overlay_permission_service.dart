import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayPermissionService {
  Future<bool> checkPermission() async {
    return await FlutterOverlayWindow.isPermissionGranted();
  }

  Future<bool> requestPermission() async {
    final granted = await FlutterOverlayWindow.requestPermission();
    return granted ?? false;
  }
}
