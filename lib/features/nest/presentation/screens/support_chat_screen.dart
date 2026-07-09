import 'dart:async';
import 'dart:ui';
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

  final List<String> _quickPrompts = [
    "Pairing issues 🔗",
    "Report a bug 🐛",
    "App suggestion 💡",
    "Billing inquiry 💳",
  ];

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
      if (_userId.isNotEmpty) {
        _supportService.markSupportChatAsRead(_userId);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage([String? customText]) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty || _userId.isEmpty) return;

    if (customText == null) {
      _messageController.clear();
    }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.softBlack.withValues(alpha: 0.6),
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
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
        title: Row(
          children: [
            // Premium Support Avatar with Live Status Glow
            Stack(
              children: [
                Container(
                  width: 38.r,
                  height: 38.r,
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
                  child: Center(
                    child: Icon(
                      Icons.headset_mic_rounded,
                      color: Colors.white,
                      size: 18.sp,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10.r,
                    height: 10.r,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.softBlack, width: 1.5.w),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withValues(alpha: 0.5),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Bae Support Hub",
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 5.r,
                      height: 5.r,
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      "We are online",
                      style: GoogleFonts.dmSans(
                        color: Colors.white38,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -50.h,
            left: -50.w,
            child: Container(
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryPurple.withValues(alpha: 0.12),
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
              width: 350.w,
              height: 350.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryPink.withValues(alpha: 0.08),
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
              bottom: false,
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
                        
                        // Mark as read when new messages load
                        if (messages.isNotEmpty && _userId.isNotEmpty) {
                          _supportService.markSupportChatAsRead(_userId);
                        }

                        return CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          reverse: true, // Newest messages at bottom
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 80.h),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    // Reversed list builder
                                    final itemIndex = messages.length - 1 - index;
                                    final msg = messages[itemIndex];
                                    final isUser = msg['senderId'] == _userId;
                                    final text = msg['text'] ?? '';
                                    final time = msg['timestamp'];

                                    // Dynamic Bubble Shapes for Grouped Message Aesthetics
                                    final hasPrevSame = itemIndex > 0 &&
                                        messages[itemIndex - 1]['senderId'] == msg['senderId'];
                                    final hasNextSame = itemIndex < messages.length - 1 &&
                                        messages[itemIndex + 1]['senderId'] == msg['senderId'];

                                    return _buildMessageBubble(
                                      text: text,
                                      isUser: isUser,
                                      time: time,
                                      hasPrevSame: hasPrevSame,
                                      hasNextSame: hasNextSame,
                                    );
                                  },
                                  childCount: messages.length,
                                ),
                              ),
                            ),
                            // Quick-action header display if chat is empty
                            if (messages.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _buildEmptyState(),
                              )
                            else
                              SliverToBoxAdapter(
                                child: _buildIntroBanner(),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  // Bottom Floating Input
                  _buildMessageInput(),
                ],
              ),
            ),

          // Scroll to Bottom Helper
          if (_showScrollBottomBtn)
            Positioned(
              bottom: 110.h,
              right: 20.w,
              child: GestureDetector(
                onTap: _scrollToBottom,
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      width: 40.r,
                      height: 40.r,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.w),
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(22.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.02),
              border: Border.all(
                color: AppColors.primaryPurple.withValues(alpha: 0.1),
                width: 1.5.w,
              ),
            ),
            child: Icon(
              Icons.support_agent_rounded,
              color: AppColors.primaryPurple,
              size: 46.sp,
            ),
          ),
          UIHelper.verticalSpace(20.h),
          Text(
            "How can we help you today?",
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          UIHelper.verticalSpace(8.h),
          Text(
            "Send a message or pick one of our quick topics below to instantly start chatting with our response team.",
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              color: Colors.white38,
              fontSize: 12.sp,
              height: 1.4,
            ),
          ),
          UIHelper.verticalSpace(24.h),
          _buildQuickActionGrid(),
        ],
      ),
    );
  }

  Widget _buildIntroBanner() {
    return Container(
      margin: EdgeInsets.fromLTRB(18.w, 16.h, 18.w, 8.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: AppColors.primaryPurple, size: 20.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              "Your communication with support is fully secure and confidential.",
              style: GoogleFonts.dmSans(
                color: Colors.white54,
                fontSize: 11.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionGrid() {
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      alignment: WrapAlignment.center,
      children: _quickPrompts.map((prompt) {
        return GestureDetector(
          onTap: () => _sendMessage(prompt),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1.w,
              ),
            ),
            child: Text(
              prompt,
              style: GoogleFonts.dmSans(
                color: Colors.white.withValues(alpha: 0.87),
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessageBubble({
    required String text,
    required bool isUser,
    required dynamic time,
    required bool hasPrevSame,
    required bool hasNextSame,
  }) {
    // Dynamic border radii for nested/grouped messaging bubbles
    final double topRadius = (isUser && hasPrevSame) ? 6.r : 16.r;
    final double bottomRadius = (isUser && hasNextSame) ? 6.r : 16.r;
    final double leftRadius = (!isUser && hasPrevSame) ? 6.r : 16.r;
    final double rightRadius = (!isUser && hasNextSame) ? 6.r : 16.r;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: hasNextSame ? 4.h : 12.h,
          top: hasPrevSame ? 0 : 4.h,
        ),
        constraints: BoxConstraints(
          maxWidth: 0.72.sw,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
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
          color: isUser ? null : const Color(0xFF1B1C33),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(isUser ? 16.r : leftRadius),
            topRight: Radius.circular(isUser ? topRadius : 16.r),
            bottomLeft: Radius.circular(isUser ? 16.r : rightRadius),
            bottomRight: Radius.circular(isUser ? bottomRadius : 16.r),
          ),
          border: isUser
              ? null
              : Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 1.w,
                ),
          boxShadow: isUser
              ? [
                  BoxShadow(
                    color: AppColors.primaryPink.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: GoogleFonts.dmSans(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 13.5.sp,
                height: 1.35,
              ),
            ),
            UIHelper.verticalSpace(4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Spacer(),
                Text(
                  _formatMessageTime(time),
                  style: GoogleFonts.dmSans(
                    color: Colors.white54,
                    fontSize: 8.5.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: const Color(0xFF16152B).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1.w,
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 4,
                    minLines: 1,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 14.sp,
                    ),
                    decoration: InputDecoration(
                      hintText: "Write a message...",
                      hintStyle: GoogleFonts.dmSans(
                        color: Colors.white30,
                        fontSize: 14.sp,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: () => _sendMessage(),
                  child: Container(
                    width: 38.r,
                    height: 38.r,
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
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
