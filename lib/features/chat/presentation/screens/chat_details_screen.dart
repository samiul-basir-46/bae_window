import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/features/chat/models/user_model.dart';
import 'package:bea_window_app/features/auth/services/cloudinary_service.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';
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
  bool _isUploadingWallpaper = false;

  void _showThemePicker(Map<String, dynamic> initialConvData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.navBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      builder: (sheetContext) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _firestore.collection('conversations').doc(widget.conversationId).snapshots(),
          builder: (streamContext, snapshot) {
            final convData = snapshot.data?.data() ?? {};
            final currentOpacity = (convData['themeOpacity'] as num?)?.toDouble() ?? 0.5;
            final currentWallpaper = convData['themeWallpaper'] as String?;

            return StatefulBuilder(
              builder: (builderContext, setModalState) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        "Chat Background Theme",
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Opacity slider
                      Row(
                        children: [
                          Text(
                            "Opacity:",
                            style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13.sp),
                          ),
                          Expanded(
                            child: Slider(
                              value: currentOpacity,
                              min: 0.0,
                              max: 1.0,
                              activeColor: AppColors.primaryPink,
                              inactiveColor: Colors.white12,
                              onChanged: (val) {
                                _firestore.collection('conversations').doc(widget.conversationId).update({
                                  'themeOpacity': val,
                                });
                              },
                            ),
                          ),
                          Text(
                            "${(currentOpacity * 100).toInt()}%",
                            style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13.sp),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      // Preset options
                      Text(
                        "Select Wallpaper",
                        style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        children: [
                          // Upload Custom option
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(source: ImageSource.gallery);
                              if (picked != null) {
                                setModalState(() {
                                  _isUploadingWallpaper = true;
                                });
                                setState(() {
                                  _isUploadingWallpaper = true;
                                });
                                try {
                                  final secureUrl = await CloudinaryService.uploadImage(File(picked.path));
                                  if (secureUrl != null) {
                                    await _firestore.collection('conversations').doc(widget.conversationId).update({
                                      'themeWallpaper': secureUrl,
                                    });
                                    if (mounted) {
                                      AppToast.show(
                                        context,
                                        title: "Wallpaper Updated",
                                        message: "Custom theme applied to chat background!",
                                        type: ToastType.success,
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    AppToast.show(
                                      context,
                                      title: "Upload Failed",
                                      message: "Could not set custom theme: $e",
                                      type: ToastType.error,
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setModalState(() {
                                      _isUploadingWallpaper = false;
                                    });
                                    setState(() {
                                      _isUploadingWallpaper = false;
                                    });
                                  }
                                }
                              }
                            },
                            child: Container(
                              width: 64.w,
                              height: 64.h,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: _isUploadingWallpaper
                                  ? const Padding(
                                      padding: EdgeInsets.all(16.0),
                                      child: CircularProgressIndicator(color: AppColors.primaryPink, strokeWidth: 2),
                                    )
                                  : Icon(Icons.add_photo_alternate_rounded, color: AppColors.primaryPink, size: 24.sp),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Preset Gradient 1
                          _buildPresetThemeOption(
                            url: "https://res.cloudinary.com/dpvo4otoj/image/upload/v1719912000/gradient_1.jpg",
                            currentWallpaper: currentWallpaper,
                          ),
                          SizedBox(width: 12.w),
                          // Preset Gradient 2
                          _buildPresetThemeOption(
                            url: "https://res.cloudinary.com/dpvo4otoj/image/upload/v1719912000/gradient_2.jpg",
                            currentWallpaper: currentWallpaper,
                          ),
                          SizedBox(width: 12.w),
                          // Default / None option
                          GestureDetector(
                            onTap: () {
                              _firestore.collection('conversations').doc(widget.conversationId).update({
                                'themeWallpaper': FieldValue.delete(),
                              });
                            },
                            child: Container(
                              width: 64.w,
                              height: 64.h,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Center(
                                child: Text(
                                  "None",
                                  style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12.sp),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPresetThemeOption({required String url, required String? currentWallpaper}) {
    final isSelected = currentWallpaper == url;
    return GestureDetector(
      onTap: () {
        _firestore.collection('conversations').doc(widget.conversationId).update({
          'themeWallpaper': url,
        });
        Navigator.pop(context);
      },
      child: Container(
        width: 64.w,
        height: 64.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : Colors.transparent,
            width: 2.w,
          ),
          image: DecorationImage(
            image: CachedNetworkImageProvider(url),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  void _showQuickReactionPicker(Map<String, dynamic> convData) {
    final List<String> emojis = ["👍", "❤️", "💙", "😂", "😮", "😢", "😡", "🔥", "🎉", "💖", "✨", "💯"];
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.navBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text(
            "Choose Quick Reaction",
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: emojis.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _firestore.collection('conversations').doc(widget.conversationId).update({
                      'quickReaction': emojis[index],
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(emojis[index], style: TextStyle(fontSize: 28.sp)),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showNicknamesDialog(Map<String, dynamic> convData) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final partnerId = widget.partnerUser.uid;
    final nicknamesMap = Map<String, String>.from(convData['nicknames'] ?? {});
    final myNicknameController = TextEditingController(text: nicknamesMap[currentUserId] ?? '');
    final partnerNicknameController = TextEditingController(text: nicknamesMap[partnerId] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.navBgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text(
            "Edit Nicknames",
            style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: myNicknameController,
                style: GoogleFonts.dmSans(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Your Nickname",
                  labelStyle: TextStyle(color: Colors.white60),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryPink)),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: partnerNicknameController,
                style: GoogleFonts.dmSans(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "${widget.partnerUser.displayName}'s Nickname",
                  labelStyle: const TextStyle(color: Colors.white60),
                  enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                  focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryPink)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () {
                _firestore.collection('conversations').doc(widget.conversationId).update({
                  'nicknames.$currentUserId': myNicknameController.text.trim(),
                  'nicknames.$partnerId': partnerNicknameController.text.trim(),
                });
                Navigator.pop(context);
              },
              child: const Text("Save", style: TextStyle(color: AppColors.primaryPink)),
            ),
          ],
        );
      },
    );
  }

  void _showSharedMedia(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharedMediaScreen(conversationId: widget.conversationId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final String currentUserId = currentUser?.uid ?? '';
    final String conversationId = widget.conversationId;
    final muteExpiry = GetStorage().read<int>('mute_until_$conversationId') ?? 0;
    final bool isMuted = muteExpiry == -1 || (muteExpiry > 0 && DateTime.now().millisecondsSinceEpoch < muteExpiry);

    return Scaffold(
      backgroundColor: AppColors.softBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Details",
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _firestore.collection('conversations').doc(widget.conversationId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: BaeLoader());
          }
          final convData = snapshot.data?.data() ?? {};
          final nicknamesMap = Map<String, String>.from(convData['nicknames'] ?? {});
          final partnerName = nicknamesMap[widget.partnerUser.uid] ?? widget.partnerUser.displayName;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: 24.h),
                // Partner Avatar & Name
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48.r,
                        backgroundColor: Colors.white10,
                        backgroundImage: widget.partnerUser.profilePicture != null && widget.partnerUser.profilePicture!.isNotEmpty
                            ? CachedNetworkImageProvider(widget.partnerUser.profilePicture!)
                            : null,
                        child: widget.partnerUser.profilePicture == null || widget.partnerUser.profilePicture!.isEmpty
                            ? Icon(Icons.person, color: Colors.white30, size: 40.sp)
                            : null,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        partnerName,
                        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        widget.partnerUser.isOnline ? "Active Now" : "Offline",
                        style: GoogleFonts.dmSans(
                          color: widget.partnerUser.isOnline ? Colors.green : Colors.white38,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),

                // Customizations Section
                _buildSectionHeader("Customization"),
                _buildListTile(
                  icon: Icons.color_lens_rounded,
                  title: "Theme / Wallpaper",
                  subtitle: convData['themeWallpaper'] != null ? "Custom wallpaper applied" : "Default background",
                  onTap: () => _showThemePicker(convData),
                  trailing: _isUploadingWallpaper ? SizedBox(width: 20.w, height: 20.h, child: const CircularProgressIndicator(color: AppColors.primaryPink, strokeWidth: 2)) : null,
                ),
                _buildListTile(
                  icon: Icons.emoji_emotions_rounded,
                  title: "Quick reaction",
                  subtitle: "Default reaction is ${convData['quickReaction'] ?? '👍'}",
                  onTap: () => _showQuickReactionPicker(convData),
                ),
                _buildListTile(
                  icon: Icons.alternate_email_rounded,
                  title: "Nicknames",
                  subtitle: "Set display names for each other",
                  onTap: () => _showNicknamesDialog(convData),
                ),

                SizedBox(height: 16.h),

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
                        builder: (context) => PinnedMessagesScreen(conversationId: widget.conversationId),
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
                        builder: (context) => SearchConversationScreen(conversationId: widget.conversationId),
                      ),
                    );
                  },
                ),
                _buildListTile(
                  icon: isMuted ? Icons.notifications_off_rounded : Icons.notifications_active_rounded,
                  title: isMuted ? "Unmute notifications" : "Mute notifications",
                  subtitle: isMuted ? "Notifications are turned off" : "Tap to mute notifications",
                  onTap: () {
                    if (isMuted) {
                      GetStorage().remove('mute_until_$conversationId');
                      _firestore.collection('conversations').doc(conversationId).set({
                        'muteSettings': {
                          currentUserId: FieldValue.delete(),
                        }
                      }, SetOptions(merge: true));
                      setState(() {});
                    } else {
                      // Mute for 8 hours by default
                      final muteUntil = DateTime.now().add(const Duration(hours: 8)).millisecondsSinceEpoch;
                      GetStorage().write('mute_until_$conversationId', muteUntil);
                      _firestore.collection('conversations').doc(conversationId).set({
                        'muteSettings': {
                          currentUserId: muteUntil,
                        }
                      }, SetOptions(merge: true));
                      setState(() {});
                      AppToast.show(context, title: "Muted", message: "Notifications muted for 8 hours", type: ToastType.success);
                    }
                  },
                ),

                SizedBox(height: 40.h),
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
        style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.dmSans(color: Colors.white30, fontSize: 12.sp),
            )
          : null,
      trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14.sp),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 4.h),
    );
  }
}
