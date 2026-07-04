import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/constants/text_font_style.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/common_widgets/custom_chat_text_field.dart';

class MessageInput extends StatefulWidget {
  final Function(String text) onSendText;
  final Function(File file, ChatMessageType type) onSendMedia;
  final Function(bool isTyping) onTypingChanged;
  final MessageModel? editingMessage;
  final VoidCallback? onCancelEdit;
  final Function(String newContent)? onFinishEdit;
  final String quickReaction;

  const MessageInput({
    super.key,
    required this.onSendText,
    required this.onSendMedia,
    required this.onTypingChanged,
    this.editingMessage,
    this.onCancelEdit,
    this.onFinishEdit,
    this.quickReaction = '👍',
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
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingMessage != null &&
        oldWidget.editingMessage != widget.editingMessage) {
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
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    if (hasText) {
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
        widget.onSendMedia(
            File(result.files.single.path!), ChatMessageType.file);
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28.r),
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
    final canSend = _hasText || isEditing;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      margin: EdgeInsets.only(
        left: 12.w,
        right: 12.w,
        bottom: 12.h + MediaQuery.of(context).padding.bottom,
        top: 4.h,
      ),
      decoration: BoxDecoration(
        color: AppColors.navBgColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: AppColors.primaryPink.withValues(alpha: 0.12),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEditing)
            Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 8.w),
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
                      padding: EdgeInsets.only(right: 8.w),
                      child: Text(
                        'Cancel',
                        style:
                            TextFontStyle.textStyle12c8E8E9FDMSans600.copyWith(
                          color: AppColors.c8E8E9F,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isEditing)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _showAttachmentMenu,
                    borderRadius: BorderRadius.circular(20.r),
                    child: Padding(
                      padding: EdgeInsets.all(8.r),
                      child: Icon(
                        Icons.add_circle_outline_rounded,
                        size: 24.sp,
                        color: AppColors.primaryPink,
                      ),
                    ),
                  ),
                ),
              SizedBox(width: 4.w),
              Expanded(
                child: CustomChatTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  hintText: isEditing ? 'Edit message...' : 'Type a message...',
                  minLines: 1,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (text) {
                    final hasText = text.trim().isNotEmpty;
                    if (hasText != _hasText) {
                      setState(() {
                        _hasText = hasText;
                      });
                    }
                    _onTextChanged();
                  },
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () {
                  if (canSend) {
                    _handleSend();
                  } else {
                    widget.onSendText(widget.quickReaction);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  padding: canSend ? EdgeInsets.all(10.r) : EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: canSend
                        ? const LinearGradient(
                            colors: [
                              AppColors.primaryPink,
                              AppColors.primaryPurple
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: canSend ? null : Colors.transparent,
                    boxShadow: canSend
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.primaryPink.withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: canSend
                      ? Icon(
                          isEditing ? Icons.check_rounded : Icons.send_rounded,
                          size: 18.sp,
                          color: Colors.white,
                        )
                      : Text(
                          widget.quickReaction,
                          style: TextStyle(fontSize: 26.sp),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
