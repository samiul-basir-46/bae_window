import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/common_widgets/custom_auth_text_field.dart';
import 'dart:ui';

class CreateTaskDialog extends StatefulWidget {
  final String partnerNickname;
  final Function(String title, String assignedTo) onCreate;

  const CreateTaskDialog({
    super.key,
    required this.partnerNickname,
    required this.onCreate,
  });

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _taskController = TextEditingController();
  String _assigned = "You";

  @override
  void dispose() {
    _taskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: AppColors.navBgColor.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1.w,
          ),
        ),
        title: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checklist_rounded,
                color: Colors.blueAccent,
                size: 24.sp,
              ),
            ),
            UIHelper.verticalSpace(12.h),
            Text(
              "Create Shared Task",
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
            ),
          ],
        ),
        contentPadding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 8.h),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomAuthTextField(
              controller: _taskController,
              hintText: "What needs to be done?",
              prefixIcon: Icons.edit_note_rounded,
            ),
            UIHelper.verticalSpace(20.h),
            Text(
              "ASSIGN TO",
              style: GoogleFonts.dmSans(
                color: Colors.white38,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            UIHelper.verticalSpace(8.h),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _assigned = "You"),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _assigned == "You"
                            ? Colors.blueAccent.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: _assigned == "You"
                              ? Colors.blueAccent
                              : Colors.white.withValues(alpha: 0.05),
                          width: 1.w,
                        ),
                      ),
                      child: Text(
                        "You",
                        style: GoogleFonts.dmSans(
                          color: _assigned == "You"
                              ? Colors.blueAccent
                              : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _assigned = "Babu"),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _assigned == "Babu"
                            ? Colors.blueAccent.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: _assigned == "Babu"
                              ? Colors.blueAccent
                              : Colors.white.withValues(alpha: 0.05),
                          width: 1.w,
                        ),
                      ),
                      child: Text(
                        widget.partnerNickname,
                        style: GoogleFonts.dmSans(
                          color: _assigned == "Babu"
                              ? Colors.blueAccent
                              : Colors.white60,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actionsPadding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 20.h),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1.w,
                      ),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: GoogleFonts.dmSans(
                      color: Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed: () {
                    final text = _taskController.text.trim();
                    if (text.isNotEmpty) {
                      widget.onCreate(text, _assigned);
                    }
                  },
                  child: Text(
                    "Create",
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                    ),
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
