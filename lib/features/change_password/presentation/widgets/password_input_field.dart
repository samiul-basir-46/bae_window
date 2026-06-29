import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

class PasswordInputField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? errorText;

  const PasswordInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.hint,
    this.errorText,
  });

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.dmSans(
            color: Colors.white38,
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        UIHelper.verticalSpace(8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: hasError 
                  ? const Color(0xFFFF5252).withValues(alpha: 0.6) 
                  : Colors.white.withValues(alpha: 0.05),
              width: 1.w,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  obscureText: _obscureText,
                  style: GoogleFonts.dmSans(color: Colors.white, fontSize: 13.sp),
                  cursorColor: const Color(0xFFFF6E7F),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.dmSans(color: Colors.white24, fontSize: 13.sp),
                    border: InputBorder.none,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                child: Icon(
                  _obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.white30,
                  size: 18.sp,
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          UIHelper.verticalSpace(6.h),
          Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: Text(
              widget.errorText!,
              style: GoogleFonts.dmSans(
                color: const Color(0xFFFF5252),
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
