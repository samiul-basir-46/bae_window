import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';

class SharedMediaScreen extends StatelessWidget {
  final String conversationId;

  const SharedMediaScreen({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Shared Media",
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .doc(conversationId)
            .collection('messages')
            .where('type', whereIn: ['image', 'video'])
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: BaeLoader());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No photos or videos shared yet.",
                style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 13.sp),
              ),
            );
          }

          return GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 8.w,
              childAspectRatio: 1.0,
            ),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final isVideo = data['type'] == 'video';
              final mediaUrl = data['content'] as String? ?? '';
              final thumbnailUrl = data['videoThumbnail'] as String?;

              return GestureDetector(
                onTap: () {
                  // Push a simple Full Screen Media Viewer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenMediaViewer(url: mediaUrl, isVideo: isVideo),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: isVideo ? (thumbnailUrl ?? mediaUrl) : mediaUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.white12),
                        errorWidget: (context, url, err) => Container(color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white24)),
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
                            child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 16.sp),
                          ),
                        ),
                    ],
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

class FullScreenMediaViewer extends StatelessWidget {
  final String url;
  final bool isVideo;

  const FullScreenMediaViewer({super.key, required this.url, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: isVideo
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library_rounded, size: 64.sp, color: Colors.white24),
                  SizedBox(height: 16.h),
                  Text(
                    "Video playback requires video player setup.",
                    style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13.sp),
                  ),
                ],
              )
            : InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  placeholder: (context, url) => const CircularProgressIndicator(color: AppColors.primaryPink),
                  errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white30, size: 48),
                ),
              ),
      ),
    );
  }
}
