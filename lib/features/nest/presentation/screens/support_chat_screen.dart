import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';
import 'package:bea_window_app/features/nest/services/support_service.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final _supportService = SupportService();
  final _authService = FirebaseAuthService();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  String _userName = "User";
  String _userEmail = "";
  String _userId = "";
  bool _isLoadingProfile = true;
  bool _showScrollBottomBtn = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadUserProfile();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final show = _scrollController.position.pixels > 200;
      if (show != _showScrollBottomBtn) {
        setState(() {
          _showScrollBottomBtn = show;
        });
      }
    }
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userId = user.uid;
      _userEmail = user.email ?? "";
      _userName = user.displayName ?? "User";
      try {
        final profile = await _authService.getUserProfile(user.uid);
        if (profile != null) {
          _userName = profile['name'] ?? user.displayName ?? "User";
        }
      } catch (_) {
        // Fallback to auth display name
      }
    }
    if (mounted) {
      setState(() {
        _isLoadingProfile = false;
      });
      // Mark support chat as read by user since they entered
      if (_userId.isNotEmpty) {
        _supportService.markSupportChatAsRead(_userId);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // reversed listview
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _userId.isEmpty) return;

    _messageController.clear();
    _scrollToBottom();

    try {
      await _supportService.sendSupportMessage(
        userId: _userId,
        text: text,
        userName: _userName,
        userEmail: _userEmail,
      );
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: "Error",
          message: "Failed to send message. Please try again.",
          type: ToastType.error,
        );
      }
    }
  }

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return '';
    }
    return DateFormat('h:mm a').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1.w,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
              size: 16.sp,
            ),
          ),
        ),
        title: Column(
          children: [
            Text(
              "Help & Support",
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Support team typically replies in minutes",
              style: GoogleFonts.dmSans(
                color: Colors.white38,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: 40.h,
            left: -80.w,
            child: Container(
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryPurple.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100.h,
            right: -80.w,
            child: Container(
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryPink.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Main Layout
          if (_isLoadingProfile)
            const Center(
              child: BaeLoader(),
            )
          else
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _supportService.watchSupportMessages(_userId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: BaeLoader(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              "Error loading chat history",
                              style: GoogleFonts.dmSans(color: Colors.redAccent),
                            ),
                          );
                        }

                        final messages = snapshot.data ?? [];
                        
                        // Mark as read when new messages load while user is active
                        if (messages.isNotEmpty && _userId.isNotEmpty) {
                          _supportService.markSupportChatAsRead(_userId);
                        }

                        if (messages.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(20.r),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(alpha: 0.03),
                                    ),
                                    child: Icon(
                                      Icons.chat_bubble_outline_rounded,
                                      color: AppColors.primaryPurple,
                                      size: 40.sp,
                                    ),
                                  ),
                                  UIHelper.verticalSpace(16.h),
                                  Text(
                                    "No messages yet",
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  UIHelper.verticalSpace(8.h),
                                  Text(
                                    "Send a message below to start a conversation with our support team. We're here to help!",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white38,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: _scrollController,
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                          reverse: true, // Show newest at the bottom
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            // Reversed list, so index 0 is the newest message (at the bottom)
                            final msg = messages[messages.length - 1 - index];
                            final isUser = msg['senderId'] == _userId;
                            final text = msg['text'] ?? '';
                            final time = msg['timestamp'];

                            return Align(
                              alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.only(bottom: 12.h),
                                constraints: BoxConstraints(
                                  maxWidth: 0.75.sw,
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                decoration: BoxDecoration(
                                  gradient: isUser
                                      ? const LinearGradient(
                                          colors: [
                                            AppColors.primaryPink,
                                            AppColors.primaryPurple,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: isUser ? null : const Color(0xFF1E2142),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(16.r),
                                    topRight: Radius.circular(16.r),
                                    bottomLeft: isUser ? Radius.circular(16.r) : Radius.zero,
                                    bottomRight: isUser ? Radius.zero : Radius.circular(16.r),
                                  ),
                                  border: isUser
                                      ? null
                                      : Border.all(
                                          color: Colors.white.withValues(alpha: 0.05),
                                          width: 1.w,
                                        ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      text,
                                      style: GoogleFonts.dmSans(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                    UIHelper.verticalSpace(6.h),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        const Spacer(),
                                        Text(
                                          _formatMessageTime(time),
                                          style: GoogleFonts.dmSans(
                                            color: Colors.white54,
                                            fontSize: 9.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),

                  // Bottom Input
                  _buildMessageInput(),
                ],
              ),
            ),

          // Scroll to Bottom Button
          if (_showScrollBottomBtn)
            Positioned(
              bottom: 100.h,
              right: 20.w,
              child: GestureDetector(
                onTap: _scrollToBottom,
                child: Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: AppColors.primaryPurple,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color: Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF141226).withValues(alpha: 0.6),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1.w,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1.w,
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: GoogleFonts.dmSans(
                    color: Colors.white38,
                    fontSize: 14.sp,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 44.r,
              height: 44.r,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPink,
                    AppColors.primaryPurple,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
