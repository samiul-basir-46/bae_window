import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class VideoMessage extends StatelessWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const VideoMessage({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  void _playVideo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerFullScreen(videoUrl: videoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _playVideo(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: 240.w,
          height: 160.h,
          color: Colors.white.withValues(alpha: 0.05),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: thumbnailUrl!,
                  width: 240.w,
                  height: 160.h,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.black26,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.black26,
                  ),
                )
              else
                Container(
                  color: Colors.white.withValues(alpha: 0.03),
                  child: Center(
                    child: Icon(
                      Icons.video_library_outlined,
                      size: 40.sp,
                      color: Colors.white24,
                    ),
                  ),
                ),
              // Play Button Overlay
              Container(
                width: 48.r,
                height: 48.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.w,
                  ),
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 28.sp,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VideoPlayerFullScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerFullScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerFullScreen> createState() => _VideoPlayerFullScreenState();
}

class _VideoPlayerFullScreenState extends State<VideoPlayerFullScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      await _videoPlayerController.initialize();
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        allowFullScreen: true,
        showOptions: false,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: BaeLoader(isFullScreen: true),
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryPink,
          handleColor: AppColors.primaryPink,
          bufferedColor: Colors.white24,
          backgroundColor: Colors.white10,
        ),
      );
      setState(() {});
    } catch (_) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

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
        child: _hasError
            ? const Text(
                'Failed to load video.',
                style: TextStyle(color: Colors.white70),
              )
            : _chewieController != null
                ? Chewie(controller: _chewieController!)
                : const BaeLoader(isFullScreen: true),
      ),
    );
  }
}
