import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bea_window_app/features/chat/models/user_model.dart';
import 'package:bea_window_app/constants/text_font_style.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final UserModel partnerUser;
  final bool isTyping;

  const ChatAppBar({
    super.key,
    required this.partnerUser,
    required this.isTyping,
  });

  @override
  Size get preferredSize => Size.fromHeight(66.h);

  String _formatLastActive(DateTime? dateTime) {
    if (dateTime == null) return 'Offline';
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'Active just now';
    } else if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Active ${difference.inHours}h ago';
    } else {
      return 'Active ${DateFormat('MMM d').format(dateTime)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: preferredSize.height + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: AppColors.navBgColor.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.w,
              ),
            ),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20.sp,
                color: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            titleSpacing: 0,
            title: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20.r,
                      backgroundColor: Colors.white10,
                      backgroundImage: partnerUser.profilePicture != null &&
                              partnerUser.profilePicture!.isNotEmpty
                          ? CachedNetworkImageProvider(partnerUser.profilePicture!)
                          : null,
                      child: partnerUser.profilePicture == null ||
                              partnerUser.profilePicture!.isEmpty
                          ? Icon(Icons.person, color: Colors.white30, size: 20.sp)
                          : null,
                    ),
                    if (partnerUser.isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12.r,
                          height: 12.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                            border: Border.all(
                              color: AppColors.softBlack,
                              width: 1.5.w,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        partnerUser.displayName,
                        style: TextFontStyle.textStyle14cFFFFFFDMSans600.copyWith(
                          fontSize: 15.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        isTyping
                            ? 'Typing...'
                            : partnerUser.isOnline
                                ? 'Active Now'
                                : _formatLastActive(partnerUser.lastActive),
                        style: TextFontStyle.textStyle12c8E8E9FDMSans600.copyWith(
                          fontSize: 11.sp,
                          color: isTyping
                              ? AppColors.primaryPink
                              : partnerUser.isOnline
                                  ? Colors.green
                                  : AppColors.c8E8E9F,
                          fontWeight: isTyping || partnerUser.isOnline
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.call_rounded, size: 22.sp, color: Colors.white),
                onPressed: () {
                  // Extensible placeholder for voice calling
                },
              ),
              IconButton(
                icon: Icon(Icons.videocam_rounded, size: 24.sp, color: Colors.white),
                onPressed: () {
                  // Extensible placeholder for video calling
                },
              ),
              SizedBox(width: 8.w),
            ],
          ),
        ),
      ),
    );
  }
}
