import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';

class MediaGrid extends StatelessWidget {
  final List<MediaItemModel> mediaItems;
  final Function(int initialIndex) onMediaTap;

  const MediaGrid({
    super.key,
    required this.mediaItems,
    required this.onMediaTap,
  });

  @override
  Widget build(BuildContext context) {
    if (mediaItems.isEmpty) return const SizedBox.shrink();

    final count = mediaItems.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: 230.w,
        color: Colors.transparent,
        child: _buildGrid(context, count),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, int count) {
    if (count == 1) {
      return _buildSingleMedia(0);
    } else if (count == 2) {
      return SizedBox(
        height: 115.h,
        child: Row(
          children: [
            Expanded(child: _buildMediaItem(0)),
            SizedBox(width: 2.w),
            Expanded(child: _buildMediaItem(1)),
          ],
        ),
      );
    } else if (count == 3) {
      return SizedBox(
        height: 160.h,
        child: Row(
          children: [
            Expanded(child: _buildMediaItem(0)),
            SizedBox(width: 2.w),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _buildMediaItem(1)),
                  SizedBox(height: 2.h),
                  Expanded(child: _buildMediaItem(2)),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // 4 or more items (2x2 grid)
      return SizedBox(
        height: 230.h,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMediaItem(0)),
                  SizedBox(width: 2.w),
                  Expanded(child: _buildMediaItem(1)),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildMediaItem(2)),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildMediaItem(3),
                        if (count > 4)
                          GestureDetector(
                            onTap: () => onMediaTap(3),
                            child: Container(
                              color: Colors.black54,
                              alignment: Alignment.center,
                              child: Text(
                                '+${count - 3}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSingleMedia(int index) {
    final item = mediaItems[index];
    final isVideo = item.type == ChatMessageType.video;

    return GestureDetector(
      onTap: () => onMediaTap(index),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImageWidget(item),
            if (isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaItem(int index) {
    final item = mediaItems[index];
    final isVideo = item.type == ChatMessageType.video;

    return GestureDetector(
      onTap: () => onMediaTap(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImageWidget(item),
          if (isVideo)
            const Center(
              child: Icon(
                Icons.play_circle_outline_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(MediaItemModel item) {
    final url = item.type == ChatMessageType.video ? (item.thumbnail ?? '') : item.url;

    if (url.isEmpty) {
      return Container(
        color: Colors.white10,
        child: const Icon(Icons.broken_image_rounded, color: Colors.white30),
      );
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(color: Colors.white10),
      errorWidget: (context, url, error) => Container(
        color: Colors.white10,
        child: const Icon(Icons.broken_image_rounded, color: Colors.white30),
      ),
    );
  }
}
