import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

class PasscodeKeypad extends StatelessWidget {
  final void Function(String digit) onDigit;
  final VoidCallback onDelete;
  final bool showBiometric;
  final VoidCallback? onBiometric;

  const PasscodeKeypad({
    super.key,
    required this.onDigit,
    required this.onDelete,
    this.showBiometric = false,
    this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _row(['1', '2', '3']),
        UIHelper.verticalSpace(16.h),
        _row(['4', '5', '6']),
        UIHelper.verticalSpace(16.h),
        _row(['7', '8', '9']),
        UIHelper.verticalSpace(16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _biometricKey(),
            _digitKey('0'),
            _deleteKey(),
          ],
        ),
      ],
    );
  }

  Widget _row(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map(_digitKey).toList(),
    );
  }

  Widget _digitKey(String label) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => onDigit(label),
        child: Container(
          width: 68.w,
          height: 68.h,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _deleteKey() {
    return GestureDetector(
      onTap: onDelete,
      child: SizedBox(
        width: 68.w,
        height: 68.h,
        child: Icon(Icons.backspace_outlined, color: Colors.white54, size: 22.sp),
      ),
    );
  }

  Widget _biometricKey() {
    if (!showBiometric) return SizedBox(width: 68.w, height: 68.h);
    return GestureDetector(
      onTap: onBiometric,
      child: SizedBox(
        width: 68.w,
        height: 68.h,
        child: Icon(Icons.fingerprint_rounded, color: AppColors.primaryPink, size: 30.sp),
      ),
    );
  }
}
