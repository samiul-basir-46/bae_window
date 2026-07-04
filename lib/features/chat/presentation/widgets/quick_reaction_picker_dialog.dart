import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class QuickReactionPickerDialog extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> convRef;
  final Future<void> Function() ensureParticipants;

  const QuickReactionPickerDialog({
    super.key,
    required this.convRef,
    required this.ensureParticipants,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> emojis = [
      "👍",
      "❤️",
      "💙",
      "😂",
      "😮",
      "😢",
      "😡",
      "🔥",
      "🎉",
      "💖",
      "✨",
      "💯"
    ];

    return AlertDialog(
      backgroundColor: AppColors.navBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      title: Text(
        "Choose Quick Reaction",
        style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold),
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
              onTap: () async {
                await ensureParticipants();
                convRef.set({
                  'quickReaction': emojis[index],
                }, SetOptions(merge: true)).catchError((e) {
                  debugPrint('🔥 Failed to write quickReaction: $e');
                });
                if (context.mounted) {
                  Navigator.pop(context);
                }
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
  }
}
