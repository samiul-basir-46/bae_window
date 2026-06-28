import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:local_auth/local_auth.dart';

class PINUnlockDialog extends StatefulWidget {
  final VoidCallback onSuccess;

  const PINUnlockDialog({super.key, required this.onSuccess});

  @override
  State<PINUnlockDialog> createState() => _PINUnlockDialogState();
}

class _PINUnlockDialogState extends State<PINUnlockDialog> {
  final LocalAuthentication auth = LocalAuthentication();
  String _pin = "";

  @override
  void initState() {
    super.initState();
    // Auto-trigger biometric prompt on dialog open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateWithBiometrics();
    });
  }

  Future<void> _authenticateWithBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (canAuthenticate) {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Unlock your private story vault',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (didAuthenticate) {
          widget.onSuccess();
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Vault Unlocked!"),
                backgroundColor: AppColors.primaryPink,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Biometric Auth Error: $e");
    }
  }

  void _onKeyPress(String val) {
    if (_pin.length < 4) {
      setState(() {
        _pin += val;
      });
      if (_pin.length == 4) {
        if (_pin == "1234") {
          widget.onSuccess();
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Incorrect PIN! Try '1234'"),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() {
            _pin = "";
          });
        }
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
            decoration: BoxDecoration(
              color: AppColors.navBgColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.w),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, color: AppColors.primaryPink, size: 36.sp),
                  UIHelper.verticalSpace(16.h),
                  Text(
                    "Enter Vault PIN",
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  UIHelper.verticalSpace(6.h),
                  Text(
                    "Hint: Use '1234' to unlock",
                    style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 11.sp),
                  ),
                  UIHelper.verticalSpace(24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final filled = index < _pin.length;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: EdgeInsets.symmetric(horizontal: 10.w),
                        width: 14.w,
                        height: 14.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: filled ? AppColors.primaryPink : Colors.transparent,
                          border: Border.all(
                            color: filled ? AppColors.primaryPink : Colors.white24,
                            width: 2.w,
                          ),
                        ),
                      );
                    }),
                  ),
                  UIHelper.verticalSpace(32.h),
                  _buildKeypad(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildKey("1"), _buildKey("2"), _buildKey("3")],
        ),
        UIHelper.verticalSpace(12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildKey("4"), _buildKey("5"), _buildKey("6")],
        ),
        UIHelper.verticalSpace(12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildKey("7"), _buildKey("8"), _buildKey("9")],
        ),
        UIHelper.verticalSpace(12.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBiometricKey(),
            _buildKey("0"),
            _buildDeleteKey(),
          ],
        ),
      ],
    );
  }

  Widget _buildKey(String label) {
    return GestureDetector(
      onTap: () => _onKeyPress(label),
      child: Container(
        width: 60.w,
        height: 60.h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteKey() {
    return GestureDetector(
      onTap: _onDelete,
      child: Container(
        width: 60.w,
        height: 60.h,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.backspace_outlined,
          color: Colors.white54,
          size: 18.sp,
        ),
      ),
    );
  }

  Widget _buildBiometricKey() {
    return GestureDetector(
      onTap: _authenticateWithBiometrics,
      child: Container(
        width: 60.w,
        height: 60.h,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.fingerprint_rounded,
          color: AppColors.primaryPink,
          size: 26.sp,
        ),
      ),
    );
  }
}
