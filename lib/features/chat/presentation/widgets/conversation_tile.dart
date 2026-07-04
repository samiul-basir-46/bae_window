import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bea_window_app/features/chat/models/conversation_model.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/constants/text_font_style.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final String currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.onTap,
    this.onLongPress,
  });

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (checkDate == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  String _getMessagePreview() {
    final otherUser = conversation.otherUser;
    final partnerUid = otherUser?.uid ?? '';
    final otherUserIsTyping = conversation.typing[partnerUid] ?? false;

    if (otherUserIsTyping) {
      return 'Typing...';
    }

    final lastMsg = conversation.lastMessage;
    if (lastMsg == null) return 'Tap to start chatting!';

    final prefix = lastMsg.senderId == currentUserId ? 'You: ' : '';

    switch (lastMsg.type) {
      case ChatMessageType.image:
        return '$prefix📷 Photo';
      case ChatMessageType.video:
        return '$prefix🎥 Video';
      case ChatMessageType.file:
        return '$prefix📁 File';
      default:
        return '$prefix${lastMsg.content}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = conversation.otherUser;
    final displayName = otherUser?.displayName ?? 'User';
    final hasUnread = (conversation.unreadCounts[currentUserId] ?? 0) > 0;
    final unreadCount = conversation.unreadCounts[currentUserId] ?? 0;
    
    final partnerUid = otherUser?.uid ?? '';
    final otherUserIsTyping = conversation.typing[partnerUid] ?? false;

    final muteExpiry = conversation.muteSettings[currentUserId] ?? 0;
    final isMuted = muteExpiry == -1 || (muteExpiry > 0 && DateTime.now().millisecondsSinceEpoch < muteExpiry);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: hasUnread
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: hasUnread
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.transparent,
          width: 1.w,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          onLongPress: onLongPress,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 26.r,
                backgroundColor: Colors.white10,
                backgroundImage: otherUser?.profilePicture != null &&
                        otherUser!.profilePicture!.isNotEmpty
                    ? CachedNetworkImageProvider(otherUser.profilePicture!)
                    : null,
                child: otherUser?.profilePicture == null ||
                        otherUser!.profilePicture!.isEmpty
                    ? Icon(Icons.person, color: Colors.white30, size: 24.sp)
                    : null,
              ),
              if (otherUser?.isOnline ?? false)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14.r,
                    height: 14.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                      border: Border.all(
                        color: AppColors.softBlack,
                        width: 2.w,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextFontStyle.textStyle14cFFFFFFDMSans600.copyWith(
              fontSize: 15.sp,
              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(
              _getMessagePreview(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextFontStyle.textStyle14c8E8E9FDMSans400.copyWith(
                fontSize: 13.sp,
                color: otherUserIsTyping
                    ? AppColors.primaryPink
                    : hasUnread
                        ? Colors.white
                        : AppColors.c8E8E9F,
                fontWeight: hasUnread || otherUserIsTyping ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(conversation.updatedAt),
                style: TextFontStyle.textStyle12c8E8E9FDMSans600.copyWith(
                  fontSize: 11.sp,
                  fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                  color: hasUnread ? Colors.white70 : AppColors.c8E8E9F,
                ),
              ),
              SizedBox(height: 6.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMuted)
                    Icon(
                      Icons.notifications_off_rounded,
                      size: 14.sp,
                      color: AppColors.primaryPink.withValues(alpha: 0.8),
                    ),
                  if (isMuted && hasUnread) SizedBox(width: 6.w),
                  if (hasUnread)
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryPink,
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                     ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
