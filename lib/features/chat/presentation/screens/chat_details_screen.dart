import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/features/chat/models/user_model.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import '../widgets/theme_picker_sheet.dart';
import '../widgets/quick_reaction_picker_dialog.dart';
import '../widgets/edit_nicknames_dialog.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';
import '../../../../helpers/ui_helpers.dart';
import 'shared_media_screen.dart';
import 'pinned_messages_screen.dart';
import 'search_conversation_screen.dart';

class ChatDetailsScreen extends StatefulWidget {
  final String conversationId;
  final UserModel partnerUser;

  const ChatDetailsScreen({
    super.key,
    required this.conversationId,
    required this.partnerUser,
  });

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _convRef =>
      _firestore.collection('conversations').doc(widget.conversationId);
  Future<void> _ensureParticipants() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final partnerId = widget.partnerUser.uid;
    try {
      await _convRef.set({
        'participants': FieldValue.arrayUnion([currentUserId, partnerId]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('⚠️ Failed to ensure participants: $e');
    }
  }

  void _showThemePicker(Map<String, dynamic> initialConvData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) {
        return ThemePickerSheet(
          convRef: _convRef,
          ensureParticipants: _ensureParticipants,
        );
      },
    );
  }

  void _showQuickReactionPicker(Map<String, dynamic> convData) {
    showDialog(
      context: context,
      builder: (context) {
        return QuickReactionPickerDialog(
          convRef: _convRef,
          ensureParticipants: _ensureParticipants,
        );
      },
    );
  }

  void _showNicknamesDialog(Map<String, dynamic> convData) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    showDialog(
      context: context,
      builder: (context) {
        return EditNicknamesDialog(
          convData: convData,
          currentUserId: currentUserId,
          partnerUser: widget.partnerUser,
          convRef: _convRef,
          ensureParticipants: _ensureParticipants,
        );
      },
    );
  }

  void _showSharedMedia(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SharedMediaScreen(conversationId: widget.conversationId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String conversationId = widget.conversationId;
    final muteExpiry =
        GetStorage().read<int>('mute_until_$conversationId') ?? 0;
    final bool isMuted = muteExpiry == -1 ||
        (muteExpiry > 0 && DateTime.now().millisecondsSinceEpoch < muteExpiry);

    return Scaffold(
      backgroundColor: AppColors.softBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              size: 20.sp, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Details",
          style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _convRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint(
                '🔥 ChatDetailsScreen StreamBuilder error: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: BaeLoader());
          }
          final convData = snapshot.data?.data() ?? {};
          final partnerName = widget.partnerUser.displayName;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                UIHelper.verticalSpace(24.h),
                // Partner Avatar & Name
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 96.r,
                        height: 96.r,
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
                                    size: 40.sp),
                                errorWidget: (context, url, error) => Icon(
                                    Icons.person,
                                    color: Colors.white30,
                                    size: 40.sp),
                              )
                            : Icon(Icons.person,
                                color: Colors.white30, size: 40.sp),
                      ),
                      UIHelper.verticalSpace(16.h),
                      Text(
                        partnerName,
                        style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold),
                      ),
                      UIHelper.verticalSpace(4.h),
                      Text(
                        widget.partnerUser.isOnline ? "Active Now" : "Offline",
                        style: GoogleFonts.dmSans(
                          color: widget.partnerUser.isOnline
                              ? Colors.green
                              : Colors.white38,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                UIHelper.verticalSpace(24.h),

                // Customizations Section
                _buildSectionHeader("Customization"),
                _buildListTile(
                  icon: Icons.color_lens_rounded,
                  title: "Theme / Wallpaper",
                  subtitle: convData['themeWallpaper'] != null
                      ? "Custom wallpaper applied"
                      : "Default background",
                  onTap: () => _showThemePicker(convData),
                ),
                _buildListTile(
                  icon: Icons.emoji_emotions_rounded,
                  title: "Quick reaction",
                  subtitle:
                      "Default reaction is ${convData['quickReaction'] ?? '👍'}",
                  onTap: () => _showQuickReactionPicker(convData),
                ),
                _buildListTile(
                  icon: Icons.alternate_email_rounded,
                  title: "Nicknames",
                  subtitle: "Set display names for each other",
                  onTap: () => _showNicknamesDialog(convData),
                ),

                UIHelper.verticalSpace(16.h),

                // Actions section
                _buildSectionHeader("More actions"),
                _buildListTile(
                  icon: Icons.photo_library_rounded,
                  title: "View media, files & links",
                  subtitle: "Browse photos and videos shared in chat",
                  onTap: () => _showSharedMedia(context),
                ),
                _buildListTile(
                  icon: Icons.push_pin_rounded,
                  title: "Pinned messages",
                  subtitle: "View pinned important messages",
                   onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PinnedMessagesScreen(
                          conversationId: widget.conversationId,
                          partnerUser: widget.partnerUser,
                        ),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  icon: Icons.search_rounded,
                  title: "Search in conversation",
                  subtitle: "Search messages inside this chat",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SearchConversationScreen(
                            conversationId: widget.conversationId),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  icon: isMuted
                      ? Icons.notifications_off_rounded
                      : Icons.notifications_active_rounded,
                  title:
                      isMuted ? "Unmute notifications" : "Mute notifications",
                  subtitle: isMuted
                      ? "Notifications are turned off"
                      : "Tap to mute notifications",
                  onTap: () {
                    AppToast.show(
                      context,
                      title: "Coming Soon",
                      message: "Mute notifications feature is coming soon!",
                      type: ToastType.info,
                    );
                  },
                ),

                UIHelper.verticalSpace(40.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.dmSans(
          color: Colors.white30,
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white70, size: 20.sp),
      ),
      title: Text(
        title,
        style: GoogleFonts.dmSans(
            color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.dmSans(color: Colors.white30, fontSize: 12.sp),
            )
          : null,
      trailing: trailing ??
          Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white24, size: 14.sp),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 4.h),
    );
  }
}
