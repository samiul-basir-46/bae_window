import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

class UnpairDialog extends StatefulWidget {
  final Function(String password) onConfirm;

  const UnpairDialog({
    super.key,
    required this.onConfirm,
  });

  @override
  State<UnpairDialog> createState() => _UnpairDialogState();
}

class _UnpairDialogState extends State<UnpairDialog> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1A1D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          contentPadding: EdgeInsets.all(24.r),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heartbreak icon container
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: const BoxDecoration(
                  color: Color(0xFF2E191D),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.heart_broken_rounded,
                  color: const Color(0xFFFF5252),
                  size: 32.sp,
                ),
              ),
              UIHelper.verticalSpace(16.h),

              // Title & Description
              Text(
                "Unpair from Bae?",
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              UIHelper.verticalSpace(8.h),
              Text(
                "This will permanently close your shared couple space.",
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: Colors.white54,
                  fontSize: 12.sp,
                ),
              ),
              UIHelper.verticalSpace(16.h),

              // Warning alert box
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF33161A),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFFF5252).withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.delete_outline_rounded, color: const Color(0xFFFF5252), size: 16.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        "Our Story, Vault, Mood history, Tasks, Bucket List — all gone for both of you, forever",
                        style: GoogleFonts.dmSans(
                          color: const Color(0xFFFF8A8A),
                          fontSize: 11.sp,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              UIHelper.verticalSpace(20.h),

              // Password field
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: TextField(
                  controller: _passwordController,
                  obscureText: true,
                  cursorColor: const Color(0xFFFF5252),
                  style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13.sp),
                  decoration: InputDecoration(
                    hintText: "Enter password",
                    hintStyle: GoogleFonts.dmSans(color: Colors.white24, fontSize: 13.sp),
                    border: InputBorder.none,
                  ),
                ),
              ),
              UIHelper.verticalSpace(24.h),

              // Buttons row
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Text(
                          "Stay paired",
                          style: GoogleFonts.dmSans(
                            color: Colors.white70,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        final pw = _passwordController.text.trim();
                        if (pw.isNotEmpty) {
                          Navigator.pop(context);
                          widget.onConfirm(pw);
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Text(
                          "Unpair",
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
  }
}
