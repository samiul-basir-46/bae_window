import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/constants/text_font_style.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class MessageInput extends StatefulWidget {
  final Function(String text) onSendText;
  final Function(File file, ChatMessageType type) onSendMedia;
  final Function(bool isTyping) onTypingChanged;
  final MessageModel? editingMessage;
  final VoidCallback? onCancelEdit;
  final Function(String newContent)? onFinishEdit;

  const MessageInput({
    super.key,
    required this.onSendText,
    required this.onSendMedia,
    required this.onTypingChanged,
    this.editingMessage,
    this.onCancelEdit,
    this.onFinishEdit,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingMessage != null && oldWidget.editingMessage != widget.editingMessage) {
      _controller.text = widget.editingMessage!.content;
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    if (_controller.text.trim().isNotEmpty) {
      if (!_isTyping) {
        _isTyping = true;
        widget.onTypingChanged(true);
      }
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(milliseconds: 1500), () {
        _isTyping = false;
        widget.onTypingChanged(false);
      });
    } else {
      if (_isTyping) {
        _isTyping = false;
        widget.onTypingChanged(false);
      }
      _typingTimer?.cancel();
    }
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (widget.editingMessage != null) {
      widget.onFinishEdit?.call(text);
    } else {
      widget.onSendText(text);
    }

    _controller.clear();
    _focusNode.unfocus();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (pickedFile != null) {
        widget.onSendMedia(File(pickedFile.path), ChatMessageType.image);
      }
    } catch (_) {}
  }

  Future<void> _pickVideo() async {
    try {
      final pickedFile = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        widget.onSendMedia(File(pickedFile.path), ChatMessageType.video);
      }
    } catch (_) {}
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );
      if (result != null && result.files.single.path != null) {
        widget.onSendMedia(File(result.files.single.path!), ChatMessageType.file);
      }
    } catch (_) {}
  }

  void _showAttachmentMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.softBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.image_rounded,
                    label: 'Image',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.video_collection_rounded,
                    label: 'Video',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file_rounded,
                    label: 'Document',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _pickFile();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1.w,
              ),
            ),
            child: Icon(icon, size: 24.sp, color: color),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextFontStyle.textStyle12c8E8E9FDMSans600.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingMessage != null;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.navBgColor,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.w,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditing)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 8.w, bottom: 8.h),
                    child: Text(
                      'Editing message...',
                      style: TextFontStyle.textStyle12c8E8E9FDMSans600.copyWith(
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onCancelEdit,
                    child: Padding(
                      padding: EdgeInsets.only(right: 8.w, bottom: 8.h),
                      child: Text(
                        'Cancel',
                        style: TextFontStyle.textStyle12c8E8E9FDMSans600.copyWith(
                          color: AppColors.c8E8E9F,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            Row(
              children: [
                if (!isEditing)
                  GestureDetector(
                    onTap: _showAttachmentMenu,
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_circle_outline_rounded,
                        size: 24.sp,
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ),
                SizedBox(width: 4.w),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1.w,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextFontStyle.textStyle14c8E8E9FDMSans400.copyWith(
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: isEditing ? 'Edit message...' : 'Type a message...',
                        hintStyle: TextFontStyle.textStyle14c949494DMSans400.copyWith(
                          color: AppColors.c8E8E9F.withValues(alpha: 0.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: _handleSend,
                  child: Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryPink, AppColors.primaryPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPink.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      isEditing ? Icons.check_rounded : Icons.send_rounded,
                      size: 18.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
