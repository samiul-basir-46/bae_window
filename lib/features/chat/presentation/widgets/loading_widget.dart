import 'package:flutter/material.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';

class LoadingWidget extends StatelessWidget {
  final bool isFullScreen;
  final double size;

  const LoadingWidget({
    super.key,
    this.isFullScreen = false,
    this.size = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    return BaeLoader(
      isFullScreen: isFullScreen,
      size: size,
    );
  }
}
