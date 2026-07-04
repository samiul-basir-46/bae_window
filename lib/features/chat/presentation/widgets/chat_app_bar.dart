import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bea_window_app/features/chat/models/user_model.dart';
import 'package:bea_window_app/constants/text_font_style.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../helpers/all_routes.dart';

class ChatAppBar extends StatefulWidget implements PreferredSizeWidget {
  final UserModel partnerUser;
  final bool isTyping;
  final String conversationId;
  final String? partnerName;

  const ChatAppBar({
    super.key,
    required this.partnerUser,
    required this.isTyping,
    required this.conversationId,
    this.partnerName,
  });

  @override
  Size get preferredSize => Size.fromHeight(66.h);

  @override
  State<ChatAppBar> createState() => _ChatAppBarState();
}

class _ChatAppBarState extends State<ChatAppBar> {
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
    final currentUser = FirebaseAuth.instance.currentUser;
    final String conversationId = widget.conversationId;
    bool isMuted = false;
    if (currentUser != null) {
      final muteExpiry =
          GetStorage().read<int>('mute_until_$conversationId') ?? 0;
      isMuted = muteExpiry == -1 ||
          (muteExpiry > 0 &&
              DateTime.now().millisecondsSinceEpoch < muteExpiry);
    }

    return AppBar(
      toolbarHeight: widget.preferredSize.height,
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.navBgColor.withValues(alpha: 0.6),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1.w,
                ),
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20.sp,
          color: Colors.white,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () => _showPartnerProfile(context),
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: const BoxDecoration(
                    color: Colors.white10,
                    shape: BoxShape.circle,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: widget.partnerUser.profilePicture != null &&
                          widget.partnerUser.profilePicture!.isNotEmpty &&
                          widget.partnerUser.profilePicture != 'null'
                      ? CachedNetworkImage(
                          imageUrl: widget.partnerUser.profilePicture!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Icon(
                              Icons.person,
                              color: Colors.white30,
                              size: 20.sp),
                          errorWidget: (context, url, error) => Icon(
                              Icons.person,
                              color: Colors.white30,
                              size: 20.sp),
                        )
                      : Icon(Icons.person,
                          color: Colors.white30, size: 20.sp),
                ),
                if (widget.partnerUser.isOnline)
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
                    widget.partnerName ?? widget.partnerUser.displayName,
                    style: TextFontStyle.textStyle14cFFFFFFDMSans600.copyWith(
                      fontSize: 15.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    widget.isTyping
                        ? 'Typing...'
                        : widget.partnerUser.isOnline
                            ? 'Active Now'
                            : _formatLastActive(widget.partnerUser.lastActive),
                    style: TextFontStyle.textStyle12c8E8E9FDMSans600.copyWith(
                      fontSize: 11.sp,
                      color: widget.isTyping
                          ? AppColors.primaryPink
                          : widget.partnerUser.isOnline
                              ? Colors.green
                              : AppColors.c8E8E9F,
                      fontWeight: widget.isTyping || widget.partnerUser.isOnline
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (isMuted)
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: Icon(Icons.notifications_off_rounded,
                size: 16.sp, color: AppColors.primaryPink),
          ),
        PopupMenuButton<String>(
          icon:
              Icon(Icons.more_vert_rounded, size: 22.sp, color: Colors.white70),
          color: AppColors.navBgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.w,
            ),
          ),
          onSelected: (value) {
            if (value == 'profile') {
              _showPartnerProfile(context);
            } else if (value == 'mute') {
              if (isMuted) {
                // Unmute locally and in Firestore
                setState(() {
                  GetStorage().remove('mute_until_$conversationId');
                });
                if (currentUser != null && conversationId.isNotEmpty) {
                  FirebaseFirestore.instance
                      .collection('conversations')
                      .doc(conversationId)
                      .set({
                    'muteSettings': {
                      currentUser.uid: FieldValue.delete(),
                    }
                  }, SetOptions(merge: true));
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications unmuted'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                _showMuteDialog(context, conversationId);
              }
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline_rounded,
                      color: Colors.white70, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text('View Profile',
                      style: TextStyle(color: Colors.white, fontSize: 13.sp)),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'mute',
              child: Row(
                children: [
                  Icon(
                      isMuted
                          ? Icons.notifications_active_outlined
                          : Icons.notifications_off_outlined,
                      color: Colors.white70,
                      size: 18.sp),
                  SizedBox(width: 8.w),
                  Text(isMuted ? 'Unmute Notifications' : 'Mute Notifications',
                      style: TextStyle(color: Colors.white, fontSize: 13.sp)),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'block',
              child: Row(
                children: [
                  Icon(Icons.block_flipped,
                      color: Colors.redAccent, size: 18.sp),
                  SizedBox(width: 8.w),
                  Text('Block Partner',
                      style:
                          TextStyle(color: Colors.redAccent, fontSize: 13.sp)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(width: 8.w),
      ],
    );
  }

  void _showMuteDialog(BuildContext context, String conversationId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        final options = [
          {'label': '5 Minutes', 'duration': const Duration(minutes: 5)},
          {'label': '10 Minutes', 'duration': const Duration(minutes: 10)},
          {'label': '1 Hour', 'duration': const Duration(hours: 1)},
          {'label': '8 Hours', 'duration': const Duration(hours: 8)},
          {'label': '1 Day', 'duration': const Duration(days: 1)},
          {'label': 'Forever (Until I change it)', 'duration': null},
        ];

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 8.w, bottom: 12.h),
                child: Text(
                  'Mute Notifications',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((opt) {
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        title: Text(
                          opt['label'] as String,
                          style:
                              TextStyle(color: Colors.white, fontSize: 14.sp),
                        ),
                        onTap: () {
                          final duration = opt['duration'] as Duration?;
                          final expiry = duration != null
                              ? DateTime.now()
                                  .add(duration)
                                  .millisecondsSinceEpoch
                              : -1;

                          setState(() {
                            GetStorage()
                                .write('mute_until_$conversationId', expiry);
                          });

                          // Write to Firestore for cloud persistence
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser != null &&
                              conversationId.isNotEmpty) {
                            FirebaseFirestore.instance
                                .collection('conversations')
                                .doc(conversationId)
                                .set({
                              'muteSettings': {
                                currentUser.uid: expiry,
                              }
                            }, SetOptions(merge: true));
                          }

                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Notifications muted for ${opt['label']}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  void _showPartnerProfile(BuildContext context) {
    Navigator.pushNamed(
      context,
      Routes.chatDetails,
      arguments: {
        'conversationId': widget.conversationId,
        'partnerUser': widget.partnerUser,
      },
    );
  }
}
