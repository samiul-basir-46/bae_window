import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/image_message.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/video_message.dart';
import 'package:bea_window_app/features/chat/presentation/widgets/file_message.dart';
import 'package:bea_window_app/constants/text_font_style.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

import '../../../../helpers/ui_helpers.dart';

class MessageBubble extends StatefulWidget {
  final MessageModel message;
  final bool isMe;
  final bool showAvatar;
  final String senderName;
  final String? senderAvatarUrl;
  final String? partnerAvatarUrl;
  final Function(MessageModel message) onSwipeToReply;
  final Function(MessageModel message, Offset position) onLongPressMessage;
  final bool isLastMessage;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.showAvatar,
    required this.senderName,
    this.senderAvatarUrl,
    this.partnerAvatarUrl,
    required this.onSwipeToReply,
    required this.onLongPressMessage,
    this.isLastMessage = false,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showTime = false;

  void _toggleShowTime() {
    setState(() {
      _showTime = !_showTime;
    });
  }

  Widget _buildMessageContent() {
    switch (widget.message.type) {
      case ChatMessageType.image:
        return ImageMessage(imageUrl: widget.message.content);
      case ChatMessageType.video:
        return VideoMessage(
          videoUrl: widget.message.content,
          thumbnailUrl: widget.message.videoThumbnail,
        );
      case ChatMessageType.file:
        return FileMessage(
          fileUrl: widget.message.content,
          fileName: widget.message.fileName,
          fileSize: widget.message.fileSize,
        );
      default:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18.r),
            gradient: widget.isMe
                ? const LinearGradient(
                    colors: [AppColors.primaryPink, AppColors.primaryPurple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: widget.isMe ? null : Colors.white.withValues(alpha: 0.05),
          ),
          child: Text.rich(
            _buildLinkifiedText(widget.message.content),
          ),
        );
    }
  }

  static final _urlRegex = RegExp(
    r'(https?://[^\s]+)',
    caseSensitive: false,
  );

  TextSpan _buildLinkifiedText(String text) {
    final matches = _urlRegex.allMatches(text);
    if (matches.isEmpty) {
      return TextSpan(
        text: text,
        style: TextFontStyle.textStyle14cFFFFFFDMSans600.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 14.5.sp,
        ),
      );
    }

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      // Add normal text before this URL
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextFontStyle.textStyle14cFFFFFFDMSans600.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w400,
            fontSize: 14.5.sp,
          ),
        ));
      }

      // Add the URL as a tappable link
      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: TextFontStyle.textStyle14cFFFFFFDMSans600.copyWith(
          color: const Color(0xFF8BB4FF),
          fontWeight: FontWeight.w500,
          fontSize: 14.5.sp,
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFF8BB4FF),
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.tryParse(url);
            if (uri != null) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
      ));

      lastEnd = match.end;
    }

    // Add remaining text after the last URL
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextFontStyle.textStyle14cFFFFFFDMSans600.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w400,
          fontSize: 14.5.sp,
        ),
      ));
    }

    return TextSpan(children: spans);
  }

  Widget _buildRepliedPreview() {
    final reply = widget.message.repliedTo;
    if (reply == null) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: 4.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.02),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            reply.senderId == widget.message.senderId
                ? 'Replied to self'
                : 'Replied to ${widget.senderName}',
            style: TextFontStyle.textStyle10c888888DMSans600.copyWith(
              color: AppColors.primaryPink.withValues(alpha: 0.8),
              fontSize: 10.sp,
              letterSpacing: 0,
            ),
          ),
          UIHelper.verticalSpace(2.h),
          Text(
            reply.type == ChatMessageType.text
                ? reply.content
                : reply.type == ChatMessageType.image
                    ? '📷 Photo'
                    : reply.type == ChatMessageType.video
                        ? '🎥 Video'
                        : '📁 File',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextFontStyle.textStyle12c606060DMSans400.copyWith(
              color: Colors.white60,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsBadge() {
    if (widget.message.reactions.isEmpty) return const SizedBox.shrink();

    // Show up to 3 distinct reactions
    final emojis = widget.message.reactions.values.toSet().take(3).toList();

    return Positioned(
      bottom: -6.h,
      right: widget.isMe ? 12.w : null,
      left: widget.isMe ? null : 12.w,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: AppColors.navBgColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emojis.join(''),
              style: TextStyle(fontSize: 10.sp),
            ),
            if (widget.message.reactions.length > 1) ...[
              UIHelper.horizontalSpace(2.w),
              Text(
                widget.message.reactions.length.toString(),
                style: TextStyle(
                  color: AppColors.c8E8E9F,
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (!widget.isMe || !widget.isLastMessage) return const SizedBox.shrink();

    String statusText = '';
    Color statusColor = AppColors.c8E8E9F.withValues(alpha: 0.7);
    bool isSeen = widget.message.status == MessageStatus.seen;

    switch (widget.message.status) {
      case MessageStatus.seen:
        statusColor = AppColors.primaryPink;
        break;
      case MessageStatus.delivered:
        statusText = 'Delivered';
        break;
      case MessageStatus.sent:
        statusText = 'Sent';
        break;
      case MessageStatus.sending:
        statusText = 'Sending...';
        break;
    }

    return Padding(
      padding: EdgeInsets.only(top: 4.h, right: 6.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isSeen) ...[
            Container(
              width: 18.r,
              height: 18.r,
              decoration: const BoxDecoration(
                color: Colors.white10,
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: widget.partnerAvatarUrl != null &&
                      widget.partnerAvatarUrl!.isNotEmpty &&
                      widget.partnerAvatarUrl != 'null'
                  ? CachedNetworkImage(
                      imageUrl: widget.partnerAvatarUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Icon(Icons.person, color: Colors.white30, size: 8.sp),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.person, color: Colors.white30, size: 8.sp),
                    )
                  : Icon(Icons.person, color: Colors.white30, size: 8.sp),
            ),
          ] else if (widget.message.status == MessageStatus.sending) ...[
            SizedBox(
              width: 8.r,
              height: 8.r,
              child: CircularProgressIndicator(
                strokeWidth: 1.w,
                valueColor: const AlwaysStoppedAnimation(AppColors.primaryPink),
              ),
            ),
            UIHelper.horizontalSpace(5.w),
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = DateFormat('h:mm a').format(widget.message.timestamp);
    final isMe = widget.isMe;

    return GestureDetector(
      onTap: _toggleShowTime,
      onLongPressStart: (details) {
        widget.onLongPressMessage(widget.message, details.globalPosition);
      },
      child: SwipeToReplyWrapper(
        isMe: isMe,
        onSwipe: () => widget.onSwipeToReply(widget.message),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 16.w),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment:
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isMe && widget.showAvatar) ...[
                    Container(
                      width: 28.r,
                      height: 28.r,
                      decoration: const BoxDecoration(
                        color: Colors.white10,
                        shape: BoxShape.circle,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: widget.senderAvatarUrl != null &&
                              widget.senderAvatarUrl!.isNotEmpty &&
                              widget.senderAvatarUrl != 'null'
                          ? CachedNetworkImage(
                              imageUrl: widget.senderAvatarUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Icon(Icons.person,
                                  color: Colors.white30, size: 14.sp),
                              errorWidget: (context, url, error) => Icon(
                                  Icons.person,
                                  color: Colors.white30,
                                  size: 14.sp),
                            )
                          : Icon(Icons.person,
                              color: Colors.white30, size: 14.sp),
                    ),
                    UIHelper.horizontalSpace(8.w),
                  ] else if (!isMe && !widget.showAvatar) ...[
                    UIHelper.horizontalSpace(
                        36.w), // alignment buffer when avatar is grouped/hidden
                  ],
                  Flexible(
                    child: Column(
                      crossAxisAlignment: isMe
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRepliedPreview(),
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            _buildMessageContent(),
                            _buildReactionsBadge(),
                            if (widget.message.isPinned)
                              Positioned(
                                top: -6.h,
                                left: isMe ? null : -6.w,
                                right: isMe ? -6.w : null,
                                child: Container(
                                  padding: EdgeInsets.all(3.r),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPink
                                        .withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Transform.rotate(
                                    angle: isMe ? 0.5 : -0.5,
                                    child: Icon(
                                      Icons.push_pin_rounded,
                                      color: Colors.white,
                                      size: 10.sp,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Show "Edited" label if applicable
              if (widget.message.isEdited)
                Padding(
                  padding: EdgeInsets.only(
                    top: 2.h,
                    right: isMe ? 4.w : 0,
                    left: isMe ? 0 : 40.w,
                  ),
                  child: Text(
                    'Edited',
                    style: TextFontStyle.textStyle10c888888DMSans600.copyWith(
                      color: AppColors.c8E8E9F.withValues(alpha: 0.6),
                      fontSize: 9.sp,
                    ),
                  ),
                ),
              // Show Time stamp toggle
              if (_showTime)
                Padding(
                  padding: EdgeInsets.only(
                    top: 4.h,
                    right: isMe ? 4.w : 0,
                    left: isMe ? 0 : 40.w,
                  ),
                  child: Text(
                    timeStr,
                    style: TextFontStyle.textStyle10c888888DMSans600.copyWith(
                      color: AppColors.c8E8E9F,
                      fontSize: 9.sp,
                    ),
                  ),
                ),
              // Read status receipts
              if (isMe)
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildStatusIndicator(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SwipeToReplyWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback onSwipe;
  final bool isMe;

  const SwipeToReplyWrapper({
    super.key,
    required this.child,
    required this.onSwipe,
    required this.isMe,
  });

  @override
  State<SwipeToReplyWrapper> createState() => _SwipeToReplyWrapperState();
}

class _SwipeToReplyWrapperState extends State<SwipeToReplyWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragOffset = 0.0;
  static const double _maxDragDistance = 60.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      if (widget.isMe) {
        _dragOffset += details.primaryDelta!;
        if (_dragOffset > 0) _dragOffset = 0;
        if (_dragOffset < -_maxDragDistance) _dragOffset = -_maxDragDistance;
      } else {
        _dragOffset += details.primaryDelta!;
        if (_dragOffset < 0) _dragOffset = 0;
        if (_dragOffset > _maxDragDistance) _dragOffset = _maxDragDistance;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragOffset.abs() >= _maxDragDistance * 0.7) {
      widget.onSwipe();
    }
    final double start = _dragOffset;
    _controller.reset();
    final Animation<double> animation = Tween<double>(
      begin: start,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    animation.addListener(() {
      setState(() {
        _dragOffset = animation.value;
      });
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: widget.isMe ? null : 16.w,
            right: widget.isMe ? 16.w : null,
            top: 0,
            bottom: 0,
            child: Center(
              child: Opacity(
                opacity: (_dragOffset.abs() / _maxDragDistance).clamp(0.0, 1.0),
                child: Icon(
                  Icons.reply_rounded,
                  color: AppColors.primaryPink,
                  size: 20.sp,
                ),
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
