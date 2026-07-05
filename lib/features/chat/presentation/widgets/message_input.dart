import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/features/chat/bloc/upload_bloc.dart';
import 'package:bea_window_app/features/chat/bloc/upload_event.dart';
import 'package:bea_window_app/features/chat/bloc/upload_state.dart';
import 'package:bea_window_app/constants/text_font_style.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/common_widgets/custom_chat_text_field.dart';

class MessageInput extends StatefulWidget {
  final Function(String text) onSendText;
  final Function(List<File> files, List<ChatMessageType> types, String? text) onSendMultipleMedia;
  final Function(bool isTyping) onTypingChanged;
  final MessageModel? editingMessage;
  final MessageModel? replyingTo;
  final VoidCallback? onCancelEdit;
  final Function(String newContent)? onFinishEdit;
  final String quickReaction;
  final FocusNode? focusNode;

  const MessageInput({
    super.key,
    required this.onSendText,
    required this.onSendMultipleMedia,
    required this.onTypingChanged,
    this.editingMessage,
    this.replyingTo,
    this.onCancelEdit,
    this.onFinishEdit,
    this.quickReaction = '👍',
    this.focusNode,
  });

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode;
  final ImagePicker _imagePicker = ImagePicker();

  Timer? _typingTimer;
  bool _isTyping = false;
  bool _hasText = false;

  // Media selection state
  final List<File> _selectedFiles = [];
  final List<ChatMessageType> _selectedTypes = [];
  bool _isButtonsExpanded = true;
  late AnimationController _toggleAnimationController;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode = widget.focusNode ?? FocusNode();
    _toggleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _toggleAnimationController.value = 1.0; // Initially expanded
  }

  @override
  void didUpdateWidget(covariant MessageInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingMessage != null &&
        widget.editingMessage?.id != oldWidget.editingMessage?.id) {
      _controller.text = widget.editingMessage!.content;
      _focusNode.requestFocus();
    }
    if (widget.replyingTo != null &&
        widget.replyingTo?.id != oldWidget.replyingTo?.id) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    _typingTimer?.cancel();
    _toggleAnimationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text;
    final hasText = text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
        // Auto-collapse buttons when user starts typing to maximize typing area
        if (hasText && _isButtonsExpanded) {
          _isButtonsExpanded = false;
          _toggleAnimationController.reverse();
        } else if (!hasText && !_isButtonsExpanded && _selectedFiles.isEmpty) {
          _isButtonsExpanded = true;
          _toggleAnimationController.forward();
        }
      });
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

  void _toggleButtons() {
    setState(() {
      _isButtonsExpanded = !_isButtonsExpanded;
      if (_isButtonsExpanded) {
        _toggleAnimationController.forward();
      } else {
        _toggleAnimationController.reverse();
      }
    });
  }

  Future<void> _pickFromCamera() async {
    // Show quick dialog for Photo vs Video
    final type = await showModalBottomSheet<ChatMessageType>(
      context: context,
      backgroundColor: AppColors.navBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryPink),
                title: const Text('Capture Photo', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ChatMessageType.image),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_rounded, color: AppColors.primaryPink),
                title: const Text('Record Video', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ChatMessageType.video),
              ),
            ],
          ),
        );
      },
    );

    if (type == null) return;

    try {
      if (type == ChatMessageType.image) {
        final pickedFile = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 70,
        );
        if (pickedFile != null) {
          setState(() {
            _selectedFiles.add(File(pickedFile.path));
            _selectedTypes.add(ChatMessageType.image);
          });
        }
      } else {
        final pickedFile = await _imagePicker.pickVideo(
          source: ImageSource.camera,
        );
        if (pickedFile != null) {
          setState(() {
            _selectedFiles.add(File(pickedFile.path));
            _selectedTypes.add(ChatMessageType.video);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    try {
      // Pick multiple files (images/videos)
      final List<XFile> pickedFiles = await _imagePicker.pickMultipleMedia();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var xFile in pickedFiles) {
            _selectedFiles.add(File(xFile.path));
            // Detect if video by extension
            final path = xFile.path.toLowerCase();
            final isVideo = path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi') || path.endsWith('.mkv');
            _selectedTypes.add(isVideo ? ChatMessageType.video : ChatMessageType.image);
          }
        });
      }
    } catch (_) {
      // Fallback to pick images if pickMultipleMedia fails on old devices
      try {
        final List<XFile> pickedImages = await _imagePicker.pickMultiImage();
        if (pickedImages.isNotEmpty) {
          setState(() {
            for (var xFile in pickedImages) {
              _selectedFiles.add(File(xFile.path));
              _selectedTypes.add(ChatMessageType.image);
            }
          });
        }
      } catch (_) {}
    }
  }

  void _removeMediaItem(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      _selectedTypes.removeAt(index);
    });
  }

  void _handleSend() {
    final text = _controller.text.trim();

    if (_selectedFiles.isNotEmpty) {
      // Trigger media upload callback
      widget.onSendMultipleMedia(
        List.from(_selectedFiles),
        List.from(_selectedTypes),
        text.isNotEmpty ? text : null,
      );
      setState(() {
        _selectedFiles.clear();
        _selectedTypes.clear();
      });
      _controller.clear();
    } else if (text.isNotEmpty) {
      if (widget.editingMessage != null) {
        widget.onFinishEdit?.call(text);
      } else {
        widget.onSendText(text);
      }
      _controller.clear();
    }
  }

  Widget _buildSelectedMediaPreview() {
    if (_selectedFiles.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 90.h,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedFiles.length,
        itemBuilder: (context, index) {
          final file = _selectedFiles[index];
          final type = _selectedTypes[index];

          return Stack(
            children: [
              Container(
                width: 74.w,
                height: 74.h,
                margin: EdgeInsets.only(right: 12.w, top: 4.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.primaryPink.withValues(alpha: 0.3),
                    width: 1.w,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: type == ChatMessageType.image
                    ? Image.file(file, fit: BoxFit.cover)
                    : Container(
                        color: Colors.black45,
                        child: Icon(Icons.play_circle_outline_rounded,
                            color: Colors.white, size: 28.sp),
                      ),
              ),
              Positioned(
                top: 0,
                right: 8.w,
                child: GestureDetector(
                  onTap: () => _removeMediaItem(index),
                  child: Container(
                    padding: EdgeInsets.all(2.r),
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        color: Colors.white, size: 14.sp),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUploadProgressWidget(UploadState state) {
    if (state is UploadingState || state is UploadingMultipleState) {
      double progress = 0.0;
      int completed = 0;
      int total = 1;

      if (state is UploadingState) {
        progress = state.progress;
      } else if (state is UploadingMultipleState) {
        progress = state.progress;
        completed = state.completedCount;
        total = state.totalCount;
      }

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    state is UploadingMultipleState
                        ? 'Uploading media $completed of $total (${(progress * 100).toInt()}%)...'
                        : 'Uploading file (${(progress * 100).toInt()}%)...',
                    style: TextFontStyle.textStyle10c888888DMSans600.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
                    minHeight: 4.h,
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: () {
                context.read<UploadBloc>().add(CancelUploadEvent());
              },
              child: Container(
                padding: EdgeInsets.all(6.r),
                decoration: const BoxDecoration(
                  color: Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded, color: Colors.white, size: 16.sp),
              ),
            ),
          ],
        ),
      );
    }

    if (state is UploadFailure) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        margin: EdgeInsets.only(bottom: 8.h),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Upload failed',
                style: TextFontStyle.textStyle12c8E8E9FDMSans600.copyWith(
                  color: Colors.redAccent,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<UploadBloc>().add(RetryUploadEvent());
              },
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                context.read<UploadBloc>().add(CancelUploadEvent());
              },
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingMessage != null;
    final canSend = _hasText || _selectedFiles.isNotEmpty || isEditing;

    return BlocBuilder<UploadBloc, UploadState>(
      builder: (context, uploadState) {
        final isUploading = uploadState is UploadingState || uploadState is UploadingMultipleState;

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
          child: IgnorePointer(
            ignoring: isUploading,
            child: Opacity(
              opacity: isUploading ? 0.6 : 1.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUploadProgressWidget(uploadState),
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
                                style: TextFontStyle.textStyle12c8E8E9FDMSans600.copyWith(
                                  color: AppColors.c8E8E9F,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  _buildSelectedMediaPreview(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Expand/Collapse toggle button
                      if (!isEditing)
                        RotationTransition(
                          turns: Tween(begin: 0.0, end: 0.5).animate(_toggleAnimationController),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _toggleButtons,
                              borderRadius: BorderRadius.circular(20.r),
                              child: Padding(
                                padding: EdgeInsets.all(8.r),
                                child: Icon(
                                  _isButtonsExpanded ? Icons.arrow_back_ios_new_rounded : Icons.add_circle_outline_rounded,
                                  size: 22.sp,
                                  color: AppColors.primaryPink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Animated media actions row
                      if (!isEditing)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          width: _isButtonsExpanded ? 80.w : 0.w,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            child: Row(
                              children: [
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _pickFromCamera,
                                    borderRadius: BorderRadius.circular(20.r),
                                    child: Padding(
                                      padding: EdgeInsets.all(8.r),
                                      child: Icon(
                                        Icons.camera_alt_rounded,
                                        size: 22.sp,
                                        color: AppColors.primaryPink,
                                      ),
                                    ),
                                  ),
                                ),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _pickFromGallery,
                                    borderRadius: BorderRadius.circular(20.r),
                                    child: Padding(
                                      padding: EdgeInsets.all(8.r),
                                      child: Icon(
                                        Icons.image_rounded,
                                        size: 22.sp,
                                        color: AppColors.primaryPink,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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
                                      color: AppColors.primaryPink.withValues(alpha: 0.3),
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
            ),
          ),
        );
      },
    );
  }
}
