import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';
import 'package:bea_window_app/helpers/firestore_cache_service.dart';
import 'package:bea_window_app/helpers/url_lunch.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import '../../../../helpers/ui_helpers.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class SharedMediaScreen extends StatelessWidget {
  final String conversationId;

  const SharedMediaScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    final cache = FirestoreCacheService.instance;

    return Scaffold(
      backgroundColor: AppColors.softBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20.sp, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Shared Files & Media",
          style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: cache.getCollection(
          query: FirebaseFirestore.instance
              .collection('conversations')
              .doc(conversationId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .limit(100),
          cacheKey: 'conversations/$conversationId/shared_media_100',
          ttl: const Duration(minutes: 10),
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: BaeLoader());
          }
          final allDocs = snapshot.data ?? [];
          final docs = allDocs.where((data) {
            final type = data['type'] as String?;
            return type != null && type != 'text';
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No shared files or media yet.",
                style:
                    GoogleFonts.dmSans(color: Colors.white38, fontSize: 13.sp),
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12.h,
              crossAxisSpacing: 12.w,
              childAspectRatio: 0.85,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              final type = data['type'] as String? ?? 'image';
              final mediaUrl = data['content'] as String? ?? '';
              final thumbnailUrl = data['videoThumbnail'] as String?;
              final fileName = data['fileName'] as String? ?? 'Shared File';
              final fileSize = data['fileSize'] as int?;

              final isVideo = type == 'video';
              final isFile = type == 'file';

              // Check if file is audio by checking name
              final isAudio = isFile &&
                  (fileName.toLowerCase().endsWith('.mp3') ||
                      fileName.toLowerCase().endsWith('.m4a') ||
                      fileName.toLowerCase().endsWith('.wav') ||
                      fileName.toLowerCase().endsWith('.aac') ||
                      fileName.toLowerCase().endsWith('.ogg') ||
                      fileName.toLowerCase().endsWith('.amr'));

              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    Routes.mediaViewer,
                    arguments: {
                      'url': mediaUrl,
                      'type': type,
                      'fileName': fileName,
                      'fileSize': fileSize,
                      'isAudio': isAudio,
                      'mediaItems': docs,
                      'initialIndex': index,
                    },
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.03),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (isFile)
                                Container(
                                  color: Colors.white.withValues(alpha: 0.02),
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.all(10.r),
                                      decoration: BoxDecoration(
                                        color: (isAudio
                                                ? AppColors.primaryPink
                                                : Colors.purple)
                                            .withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isAudio
                                            ? Icons.music_note_rounded
                                            : Icons.insert_drive_file_rounded,
                                        color: isAudio
                                            ? AppColors.primaryPink
                                            : Colors.purpleAccent,
                                        size: 26.sp,
                                      ),
                                    ),
                                  ),
                                )
                              else
                                CachedNetworkImage(
                                  imageUrl: isVideo
                                      ? (thumbnailUrl ?? mediaUrl)
                                      : mediaUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Container(color: Colors.white12),
                                  errorWidget: (context, url, err) => Container(
                                    color: Colors.white10,
                                    child: const Icon(Icons.broken_image,
                                        color: Colors.white24),
                                  ),
                                ),
                              if (isVideo)
                                Positioned(
                                  right: 8.w,
                                  top: 8.h,
                                  child: Container(
                                    padding: EdgeInsets.all(4.r),
                                    decoration: const BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.play_arrow_rounded,
                                        color: Colors.white, size: 14.sp),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 6.h),
                          child: Text(
                            isFile ? fileName : (isVideo ? "Video" : "Photo"),
                            style: GoogleFonts.dmSans(
                              color: Colors.white70,
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FullScreenMediaViewer extends StatefulWidget {
  final String url;
  final String type;
  final String fileName;
  final int? fileSize;
  final bool isAudio;
  final List<Map<String, dynamic>> mediaItems;
  final int initialIndex;

  const FullScreenMediaViewer({
    super.key,
    required this.url,
    required this.type,
    required this.fileName,
    this.fileSize,
    required this.isAudio,
    this.mediaItems = const [],
    this.initialIndex = 0,
  });

  @override
  State<FullScreenMediaViewer> createState() => _FullScreenMediaViewerState();
}

class _FullScreenMediaViewerState extends State<FullScreenMediaViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return "Unknown size";
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  @override
  Widget build(BuildContext context) {
    final hasGallery = widget.mediaItems.isNotEmpty;
    final totalItems = hasGallery ? widget.mediaItems.length : 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          hasGallery ? "${_currentIndex + 1} of $totalItems" : "",
          style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14.sp),
        ),
        centerTitle: true,
      ),
      body: hasGallery
          ? PageView.builder(
              controller: _pageController,
              itemCount: totalItems,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final data = widget.mediaItems[index];
                final type = data['type'] as String? ?? 'image';
                final url = data['content'] as String? ?? '';
                final fileName = data['fileName'] as String? ?? 'Shared File';
                final fileSize = data['fileSize'] as int?;
                final isVideo = type == 'video';
                final isFile = type == 'file';

                final isAudio = isFile &&
                    (fileName.toLowerCase().endsWith('.mp3') ||
                        fileName.toLowerCase().endsWith('.m4a') ||
                        fileName.toLowerCase().endsWith('.wav') ||
                        fileName.toLowerCase().endsWith('.aac') ||
                        fileName.toLowerCase().endsWith('.ogg') ||
                        fileName.toLowerCase().endsWith('.amr'));

                return _buildMediaContent(
                  url: url,
                  type: type,
                  fileName: fileName,
                  fileSize: fileSize,
                  isVideo: isVideo,
                  isFile: isFile,
                  isAudio: isAudio,
                );
              },
            )
          : _buildMediaContent(
              url: widget.url,
              type: widget.type,
              fileName: widget.fileName,
              fileSize: widget.fileSize,
              isVideo: widget.type == 'video',
              isFile: widget.type == 'file',
              isAudio: widget.isAudio,
            ),
    );
  }

  Widget _buildMediaContent({
    required String url,
    required String type,
    required String fileName,
    required int? fileSize,
    required bool isVideo,
    required bool isFile,
    required bool isAudio,
  }) {
    return Center(
      child: isFile
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: (isAudio ? AppColors.primaryPink : Colors.purple)
                            .withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isAudio
                            ? Icons.audiotrack_rounded
                            : Icons.insert_drive_file_rounded,
                        color: isAudio
                            ? AppColors.primaryPink
                            : Colors.purpleAccent,
                        size: 48.sp,
                      ),
                    ),
                    UIHelper.verticalSpace(16.h),
                    Text(
                      fileName,
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    UIHelper.verticalSpace(8.h),
                    Text(
                      _formatFileSize(fileSize),
                      style: GoogleFonts.dmSans(
                        color: Colors.white38,
                        fontSize: 13.sp,
                      ),
                    ),
                    UIHelper.verticalSpace(24.h),
                    ElevatedButton.icon(
                      onPressed: () => urlLunch(url),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 12.h),
                      ),
                      icon: Icon(isAudio
                          ? Icons.play_arrow_rounded
                          : Icons.open_in_new_rounded),
                      label: Text(
                        isAudio ? "Play Audio File" : "Open Document",
                        style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold, fontSize: 14.sp),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : (isVideo
              ? _InlineVideoPlayer(videoUrl: url)
              : InteractiveViewer(
                  child: CachedNetworkImage(
                    imageUrl: url,
                    placeholder: (context, url) =>
                        const CircularProgressIndicator(
                            color: AppColors.primaryPink),
                    errorWidget: (context, url, error) => const Icon(
                        Icons.broken_image,
                        color: Colors.white30,
                        size: 48),
                  ),
                )),
    );
  }
}

class _InlineVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _InlineVideoPlayer({required this.videoUrl});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
      await _videoController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController.value.aspectRatio,
        showOptions: false,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryPink,
          handleColor: AppColors.primaryPink,
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white10,
        ),
      );
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Text(
          'Failed to load video.',
          style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13.sp),
        ),
      );
    }
    if (_chewieController == null) {
      return const Center(child: BaeLoader(isFullScreen: true));
    }
    return Chewie(controller: _chewieController!);
  }
}
