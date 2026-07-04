import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/features/chat/models/user_model.dart';
import '../../../../helpers/ui_helpers.dart';

class EditNicknamesDialog extends StatefulWidget {
  final Map<String, dynamic> convData;
  final String currentUserId;
  final UserModel partnerUser;
  final DocumentReference<Map<String, dynamic>> convRef;
  final Future<void> Function() ensureParticipants;

  const EditNicknamesDialog({
    super.key,
    required this.convData,
    required this.currentUserId,
    required this.partnerUser,
    required this.convRef,
    required this.ensureParticipants,
  });

  @override
  State<EditNicknamesDialog> createState() => _EditNicknamesDialogState();
}

class _EditNicknamesDialogState extends State<EditNicknamesDialog> {
  late TextEditingController myNicknameController;
  late TextEditingController partnerNicknameController;

  @override
  void initState() {
    super.initState();
    final nicknamesMap = Map<String, String>.from(widget.convData['nicknames'] ?? {});
    myNicknameController =
        TextEditingController(text: nicknamesMap[widget.currentUserId] ?? '');
    partnerNicknameController =
        TextEditingController(text: nicknamesMap[widget.partnerUser.uid] ?? '');
  }

  @override
  void dispose() {
    myNicknameController.dispose();
    partnerNicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.navBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: AppColors.primaryPink,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  "Edit Nicknames",
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            UIHelper.verticalSpace(8.h),
            Text(
              "Nicknames will only be shown in the chat view. Leave a nickname empty to display the real name.",
              style: GoogleFonts.dmSans(
                color: Colors.white38,
                fontSize: 12.sp,
              ),
            ),
            UIHelper.verticalSpace(20.h),
            // Your Nickname Input
            Text(
              "Your Nickname",
              style: GoogleFonts.dmSans(
                color: Colors.white70,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            UIHelper.verticalSpace(8.h),
            TextField(
              controller: myNicknameController,
              style: GoogleFonts.dmSans(color: Colors.white),
              cursorColor: AppColors.primaryPink,
              decoration: InputDecoration(
                hintText: "Enter your nickname...",
                hintStyle:
                    TextStyle(color: Colors.white30, fontSize: 13.sp),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide:
                      const BorderSide(color: AppColors.primaryPink),
                ),
              ),
            ),
            UIHelper.verticalSpace(16.h),
            // Partner Nickname Input
            Text(
              "${widget.partnerUser.displayName}'s Nickname",
              style: GoogleFonts.dmSans(
                color: Colors.white70,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            UIHelper.verticalSpace(8.h),
            TextField(
              controller: partnerNicknameController,
              style: GoogleFonts.dmSans(color: Colors.white),
              cursorColor: AppColors.primaryPink,
              decoration: InputDecoration(
                hintText: "Enter partner's nickname...",
                hintStyle:
                    TextStyle(color: Colors.white30, fontSize: 13.sp),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.03),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide:
                      const BorderSide(color: AppColors.primaryPink),
                ),
              ),
            ),
            UIHelper.verticalSpace(24.h),
            // Dialog Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.dmSans(
                      color: Colors.white54,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                ElevatedButton(
                  onPressed: () async {
                    await widget.ensureParticipants();
                    widget.convRef.set({
                      'nicknames': {
                        widget.currentUserId: myNicknameController.text.trim(),
                        widget.partnerUser.uid: partnerNicknameController.text.trim(),
                      }
                    }, SetOptions(merge: true)).catchError((e) {
                      debugPrint('🔥 Failed to write nicknames: $e');
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 12.h),
                  ),
                  child: Text(
                    "Save Nicknames",
                    style: GoogleFonts.dmSans(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
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
