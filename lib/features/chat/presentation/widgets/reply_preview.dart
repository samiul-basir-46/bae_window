import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/constants/text_font_style.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class ReplyPreview extends StatelessWidget {
  final MessageModel message;
  final String senderName;
  final VoidCallback onCancel;

  const ReplyPreview({
    super.key,
    required this.message,
    required this.senderName,
    required this.onCancel,
  });

  String _getSnippet() {
    switch (message.type) {
      case ChatMessageType.image:
        return '📷 Photo';
      case ChatMessageType.video:
        return '🎥 Video';
      case ChatMessageType.file:
        return '📁 File: ${message.fileName ?? "Attachment"}';
      default:
        return message.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.navBgColor,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1.w),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 36.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryPink, AppColors.primaryPurple],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to $senderName',
                  style: TextFontStyle.textStyle12c8E8E9FDMSans600.copyWith(
                    color: AppColors.primaryPink,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _getSnippet(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextFontStyle.textStyle14c8E8E9FDMSans400.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(
              Icons.close_rounded,
              size: 20.sp,
              color: Colors.white60,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
