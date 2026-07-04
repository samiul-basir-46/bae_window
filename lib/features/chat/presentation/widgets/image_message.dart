import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';

class ImageMessage extends StatelessWidget {
  final String imageUrl;

  const ImageMessage({super.key, required this.imageUrl});

  void _openFullScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageFullScreenViewer(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFullScreen(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 240.w,
            maxHeight: 240.h,
          ),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              width: 240.w,
              height: 180.h,
              color: Colors.white.withValues(alpha: 0.05),
              child: const Center(
                child: BaeLoader(isFullScreen: false, size: 24),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              width: 240.w,
              height: 180.h,
              color: Colors.white.withValues(alpha: 0.05),
              child: const Center(
                child: Icon(Icons.broken_image_outlined, color: Colors.white38),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ImageFullScreenViewer extends StatelessWidget {
  final String imageUrl;

  const ImageFullScreenViewer({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => const BaeLoader(isFullScreen: true),
            errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white54),
          ),
        ),
      ),
    );
  }
}
