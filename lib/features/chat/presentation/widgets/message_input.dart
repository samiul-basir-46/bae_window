import 'dart:async';
import 'dart:io';
import 'package:bea_window_app/gen/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bea_window_app/features/chat/models/message_model.dart';
import 'package:bea_window_app/features/chat/bloc/upload_bloc.dart';
import 'package:bea_window_app/features/chat/bloc/upload_event.dart';
import 'package:bea_window_app/features/chat/bloc/upload_state.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/common_widgets/custom_chat_text_field.dart';

// ── Cached icon color — created once, never recreated on rebuild ───────────
final _kIconColor = AppColors.primaryPink.withValues(alpha: 0.85);

class MessageInput extends StatefulWidget {
  final Function(String text) onSendText;
  final Function(List<File> files, List<ChatMessageType> types, String? text)
      onSendMultipleMedia;
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

class _MessageInputState extends State<MessageInput>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late final FocusNode _focusNode;
  final ImagePicker _imagePicker = ImagePicker();

  Timer? _typingTimer;
  bool _isTyping = false;
  bool _hasText = false;
  bool _isExpanded = true;

  final List<File> _selectedFiles = [];
  final List<ChatMessageType> _selectedTypes = [];

  late AnimationController _expandController;
  late AnimationController _sendController;
  late Animation<double> _expandAnim;
  late Animation<double> _sendScaleAnim;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    // ── Only one listener — removed duplicate onChanged call ──────────────
    _controller.addListener(_onTextChanged);

    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    _expandAnim = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOutCubic,
    );

    _sendController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _sendScaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sendController, curve: Curves.elasticOut),
    );
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
    if (widget.focusNode == null) _focusNode.dispose();
    _typingTimer?.cancel();
    _expandController.dispose();
    _sendController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _sendController.forward();
        if (_isExpanded) _setExpanded(false);
      } else if (!hasText && _selectedFiles.isEmpty) {
        _sendController.reverse();
        if (!_isExpanded) _setExpanded(true);
      }
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

  void _setExpanded(bool value) {
    setState(() => _isExpanded = value);
    if (value) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }
  }

  void _toggleExpand() => _setExpanded(!_isExpanded);

  Future<void> _pickFromCamera() async {
    final type = await showModalBottomSheet<ChatMessageType>(
      context: context,
      backgroundColor: AppColors.navBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.primaryPink),
              title: const Text('Capture Photo',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ChatMessageType.image),
            ),
            ListTile(
              leading: const Icon(Icons.videocam_rounded,
                  color: AppColors.primaryPink),
              title: const Text('Record Video',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ChatMessageType.video),
            ),
          ],
        ),
      ),
    );

    if (type == null) return;
    try {
      if (type == ChatMessageType.image) {
        final f = await _imagePicker.pickImage(
            source: ImageSource.camera, imageQuality: 70);
        if (f != null) {
          setState(() {
            _selectedFiles.add(File(f.path));
            _selectedTypes.add(ChatMessageType.image);
          });
        }
      } else {
        final f = await _imagePicker.pickVideo(source: ImageSource.camera);
        if (f != null) {
          setState(() {
            _selectedFiles.add(File(f.path));
            _selectedTypes.add(ChatMessageType.video);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _imagePicker.pickMultipleMedia();
      if (picked.isNotEmpty) {
        setState(() {
          for (final x in picked) {
            _selectedFiles.add(File(x.path));
            final p = x.path.toLowerCase();
            _selectedTypes.add(
              (p.endsWith('.mp4') ||
                      p.endsWith('.mov') ||
                      p.endsWith('.avi') ||
                      p.endsWith('.mkv'))
                  ? ChatMessageType.video
                  : ChatMessageType.image,
            );
          }
        });
      }
    } catch (_) {
      try {
        final picked = await _imagePicker.pickMultiImage();
        if (picked.isNotEmpty) {
          setState(() {
            for (final x in picked) {
              _selectedFiles.add(File(x.path));
              _selectedTypes.add(ChatMessageType.image);
            }
          });
        }
      } catch (_) {}
    }
  }

  void _removeMedia(int index) => setState(() {
        _selectedFiles.removeAt(index);
        _selectedTypes.removeAt(index);
        if (_selectedFiles.isEmpty && !_hasText) {
          _sendController.reverse();
          _setExpanded(true);
        }
      });

  void _handleSend() {
    final text = _controller.text.trim();
    if (_selectedFiles.isNotEmpty) {
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

  Widget _buildMediaPreview() {
    if (_selectedFiles.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 80.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(bottom: 6.h),
        itemCount: _selectedFiles.length,
        itemBuilder: (_, i) {
          final isVideo = _selectedTypes[i] == ChatMessageType.video;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 66.w,
                height: 66.w,
                margin: EdgeInsets.only(right: 8.w, top: 4.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.primaryPink.withValues(alpha: 0.25),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: isVideo
                    ? Container(
                        color: Colors.black54,
                        child: Icon(Icons.play_circle_outline_rounded,
                            color: Colors.white70, size: 24.sp),
                      )
                    : Image.file(_selectedFiles[i], fit: BoxFit.cover),
              ),
              Positioned(
                top: 0,
                right: 2.w,
                child: GestureDetector(
                  onTap: () => _removeMedia(i),
                  child: Container(
                    width: 17.r,
                    height: 17.r,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 0.5),
                    ),
                    child: Icon(Icons.close_rounded,
                        color: Colors.white, size: 10.sp),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ── Upload progress — extracted so BlocBuilder scope is minimal ──────────
  Widget _buildUploadProgress(UploadState state) {
    double progress = 0;
    String label = '';

    if (state is UploadingState) {
      progress = state.progress;
      label = 'Uploading… ${(progress * 100).toInt()}%';
    } else if (state is UploadingMultipleState) {
      progress = state.progress;
      label =
          'Uploading ${state.completedCount + 1} of ${state.totalCount}… ${(progress * 100).toInt()}%';
    } else if (state is UploadFailure) {
      return Padding(
        padding: EdgeInsets.only(bottom: 6.h),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded,
                color: Colors.redAccent, size: 15.sp),
            SizedBox(width: 6.w),
            Expanded(
              child: Text('Upload failed',
                  style:
                      TextStyle(color: Colors.redAccent, fontSize: 11.sp)),
            ),
            GestureDetector(
              onTap: () =>
                  context.read<UploadBloc>().add(RetryUploadEvent()),
              child: Text('Retry',
                  style: TextStyle(
                      color: AppColors.primaryPink,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600)),
            ),
            SizedBox(width: 10.w),
            GestureDetector(
              onTap: () =>
                  context.read<UploadBloc>().add(CancelUploadEvent()),
              child: Icon(Icons.close_rounded,
                  color: Colors.white54, size: 15.sp),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style:
                        TextStyle(color: Colors.white54, fontSize: 10.sp)),
                SizedBox(height: 3.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 2,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryPink),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          GestureDetector(
            onTap: () =>
                context.read<UploadBloc>().add(CancelUploadEvent()),
            child: Icon(Icons.close_rounded,
                color: Colors.white38, size: 16.sp),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingMessage != null;
    final canSend = _hasText || _selectedFiles.isNotEmpty || isEditing;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 10.w,
        right: 10.w,
        bottom: bottomPad > 0 ? bottomPad : 8.h,
        top: 4.h,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.navBgColor,
          borderRadius: BorderRadius.circular(26.r),
          border: Border.all(
            color: AppColors.primaryPink.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Padding(
          padding:
              EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── BlocBuilder scoped only to upload progress ──────────────
              BlocBuilder<UploadBloc, UploadState>(
                buildWhen: (prev, curr) =>
                    prev.runtimeType != curr.runtimeType ||
                    (curr is UploadingState &&
                        prev is UploadingState &&
                        curr.progress != prev.progress) ||
                    (curr is UploadingMultipleState &&
                        prev is UploadingMultipleState &&
                        curr.progress != prev.progress),
                builder: (context, uploadState) =>
                    _buildUploadProgress(uploadState),
              ),

              // editing banner
              if (isEditing)
                Padding(
                  padding: EdgeInsets.only(bottom: 4.h, left: 4.w),
                  child: Row(
                    children: [
                      Icon(Icons.edit_rounded,
                          size: 12.sp, color: AppColors.primaryPink),
                      SizedBox(width: 4.w),
                      Expanded(
                        child: Text(
                          'Editing message',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.primaryPink,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onCancelEdit,
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.white38,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              _buildMediaPreview(),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!isEditing) ...[
                    _buildIconButton(
                      icon: _isExpanded
                          ? Assets.icons.back.path
                          : Assets.icons.plus.path,
                      onTap: _toggleExpand,
                    ),
                    SizeTransition(
                      sizeFactor: _expandAnim,
                      axis: Axis.horizontal,
                      axisAlignment: -1,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildIconButton(
                            icon: Assets.icons.camera.path,
                            onTap: _pickFromCamera,
                          ),
                          _buildIconButton(
                            icon: Assets.icons.gallery.path,
                            onTap: _pickFromGallery,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 2.w),
                  ],

                  // ── text field — no wrapper Container, saves a layer ────
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: 34.h),
                      child: CustomChatTextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        hintText:
                            isEditing ? 'Edit message...' : 'Message...',
                        minLines: 1,
                        maxLines: 5,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                        // ── onChanged removed — addListener handles it ───
                      ),
                    ),
                  ),

                  SizedBox(width: 6.w),

                  _buildSendButton(canSend, isEditing),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Icon button — ColorFilter created once at top level ──────────────────
  Widget _buildIconButton({
    required String icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.all(6.r),
        child: Image.asset(
          icon,
          height: 22.h,
          color: _kIconColor,
        ),
      ),
    );
  }

  Widget _buildSendButton(bool canSend, bool isEditing) {
    if (canSend) {
      return ScaleTransition(
        scale: _sendScaleAnim,
        child: GestureDetector(
          onTap: _handleSend,
          child: Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primaryPink, AppColors.primaryPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryPink.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                isEditing
                    ? Assets.icons.check.path
                    : Assets.icons.send.path,
                color: Colors.white,
                height: 22.h,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => widget.onSendText(widget.quickReaction),
      child: AnimatedScale(
        scale: canSend ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: SizedBox(
          width: 36.r,
          height: 36.r,
          child: Center(
            child: Text(
              widget.quickReaction,
              style: TextStyle(fontSize: 24.sp),
            ),
          ),
        ),
      ),
    );
  }
}