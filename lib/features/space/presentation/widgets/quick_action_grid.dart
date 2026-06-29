import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'springy_card.dart';

class QuickActionGrid extends StatefulWidget {
  final double taskProgress;
  final String nextTaskTitle;
  final Function(String note) onSendLoveNote;

  const QuickActionGrid({
    super.key,
    required this.taskProgress,
    required this.nextTaskTitle,
    required this.onSendLoveNote,
  });

  @override
  State<QuickActionGrid> createState() => _QuickActionGridState();
}

class _QuickActionGridState extends State<QuickActionGrid> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final note = _noteController.text.trim();
    if (note.isEmpty) return;
    widget.onSendLoveNote(note);
    _noteController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: SpringyCard(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Redirecting to Private Vault..."),
                      backgroundColor: AppColors.primaryPurple,
                    ),
                  );
                },
                child: _buildGridItem(
                  icon: Icons.lock_outline_rounded,
                  iconColor: AppColors.primaryPurple,
                  title: "Vault",
                  subtitle: "Access private shared media",
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: SpringyCard(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Opening Bucket List..."),
                      backgroundColor: AppColors.primaryPink,
                    ),
                  );
                },
                child: _buildGridItem(
                  icon: Icons.favorite_border_rounded,
                  iconColor: AppColors.primaryPink,
                  title: "Bucket List",
                  subtitle: "Next: Visit Paris 🗼",
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        Row(
          children: [
            Expanded(
              child: SpringyCard(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Opening Tasks Screen..."),
                      backgroundColor: Colors.blueAccent,
                    ),
                  );
                },
                child: _buildGridItem(
                  icon: Icons.checklist_rounded,
                  iconColor: Colors.blueAccent,
                  title: "Tasks",
                  subtitle: "Next: ${widget.nextTaskTitle}",
                  progress: widget.taskProgress,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: SpringyCard(
                onTap: () {}, // Trailing input handles submission
                child: _buildGridItem(
                  icon: Icons.edit_note_rounded,
                  iconColor: Colors.tealAccent,
                  title: "Love Note",
                  customContent: _buildLoveNoteInput(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    double? progress,
    Widget? customContent,
  }) {
    return Container(
      height: 140.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1.w,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.all(16.r),
            color: Colors.white.withValues(alpha: 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 16.sp),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      title,
                      style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (customContent != null)
                  Expanded(child: customContent)
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subtitle ?? "",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 11.sp,
                        ),
                      ),
                      if (progress != null) ...[
                        UIHelper.verticalSpace(8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6.r),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4.h,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                          ),
                        ),
                      ]
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoveNoteInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: TextField(
              controller: _noteController,
              cursorColor: Colors.tealAccent,
              maxLines: 1,
              style: GoogleFonts.dmSans(color: Colors.white, fontSize: 11.sp),
              decoration: InputDecoration(
                hintText: "Type note...",
                hintStyle: GoogleFonts.dmSans(color: Colors.white24, fontSize: 10.sp),
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: _handleSend,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.tealAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_rounded, color: Colors.tealAccent, size: 10.sp),
                SizedBox(width: 4.w),
                Text(
                  "Send",
                  style: GoogleFonts.dmSans(
                    color: Colors.tealAccent,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
