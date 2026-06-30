import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class ProfileAvatar extends StatelessWidget {
  final VoidCallback onTap;
  final String? avatarUrl;
  final File? localFile;
  final bool isUploading;

  const ProfileAvatar({
    super.key,
    required this.onTap,
    this.avatarUrl,
    this.localFile,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocalFile = localFile != null;
    final hasNetworkImage = avatarUrl != null && avatarUrl!.isNotEmpty;
    final hasImage = hasLocalFile || hasNetworkImage;

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 110.w,
            height: 110.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasImage
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF6A82FF), Color(0xFF9868FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 3.w,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ClipOval(
              child: _buildImageContent(),
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 2.h, right: 2.w),
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: isUploading
                  ? Colors.white.withValues(alpha: 0.3)
                  : const Color(0xFFFF6E7F),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.softBlack, width: 2.w),
            ),
            child: isUploading
                ? SizedBox(
                    width: 14.sp,
                    height: 14.sp,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 14.sp,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageContent() {
    if (localFile != null) {
      // শুধু ছবি দেখাও, কোনো overlay/spinner ঢাকনা না
      return Image.file(
        localFile!,
        fit: BoxFit.cover,
        width: 110.w,
        height: 110.h,
      );
    }

    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return Image.network(
        avatarUrl!,
        fit: BoxFit.cover,
        width: 110.w,
        height: 110.h,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.white.withValues(alpha: 0.05),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('ProfileAvatar: failed to load image — $error');
          return Icon(
            Icons.person_rounded,
            color: Colors.white.withValues(alpha: 0.7),
            size: 44.sp,
          );
        },
      );
    }

    return Icon(
      Icons.person_rounded,
      color: Colors.white.withValues(alpha: 0.7),
      size: 44.sp,
    );
  }
}
