import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

class DeleteAccountVerifyDialog extends StatefulWidget {
  final String email;
  final Function(String password) onVerify;

  const DeleteAccountVerifyDialog({
    super.key,
    required this.email,
    required this.onVerify,
  });

  @override
  State<DeleteAccountVerifyDialog> createState() => _DeleteAccountVerifyDialogState();
}

class _DeleteAccountVerifyDialogState extends State<DeleteAccountVerifyDialog> {
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
          backgroundColor: const Color(0xFF1B1B1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          contentPadding: EdgeInsets.all(24.r),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lock icon
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_rounded,
                  color: Colors.amber,
                  size: 32.sp,
                ),
              ),
              UIHelper.verticalSpace(16.h),

              // Title & Subtitle
              Text(
                "Confirm it's you",
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              UIHelper.verticalSpace(8.h),
              Text(
                "For security, please re-enter your password to continue.",
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: Colors.white54,
                  fontSize: 12.sp,
                ),
              ),
              UIHelper.verticalSpace(20.h),

              // Email (Read-only)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.01),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
                ),
                child: Text(
                  widget.email,
                  style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 13.sp),
                ),
              ),
              UIHelper.verticalSpace(12.h),

              // Password input
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
                    hintText: "Password",
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
                          "Cancel",
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
                          widget.onVerify(pw);
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
                          "Continue",
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

class DeleteAccountConfirmDialog extends StatelessWidget {
  final VoidCallback onDeleteForever;

  const DeleteAccountConfirmDialog({
    super.key,
    required this.onDeleteForever,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: AlertDialog(
          backgroundColor: const Color(0xFF1B1B1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.r)),
          contentPadding: EdgeInsets.all(24.r),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning triangle icon
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.amber,
                  size: 32.sp,
                ),
              ),
              UIHelper.verticalSpace(16.h),

              // Title & Description
              Text(
                "This can't be undone",
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              UIHelper.verticalSpace(8.h),
              Text(
                "All your memories, photos, and mood history will be erased forever. Your partner will lose access to all shared data too.",
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: Colors.white54,
                  fontSize: 12.sp,
                  height: 1.4,
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
                        "Our Story, Vault, Tasks, Bucket List — all permanently deleted",
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
                          "Keep my account",
                          style: GoogleFonts.dmSans(
                            color: Colors.white70,
                            fontSize: 12.sp,
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
                        Navigator.pop(context);
                        onDeleteForever();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5252),
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        child: Text(
                          "Delete forever",
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 12.sp,
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
