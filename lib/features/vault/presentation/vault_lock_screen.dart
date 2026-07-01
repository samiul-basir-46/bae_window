import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../bloc/vault_bloc.dart';
import '../bloc/vault_event.dart';
import '../bloc/vault_state.dart';

class VaultLockScreen extends StatefulWidget {
  final VaultState state;

  const VaultLockScreen({
    super.key,
    required this.state,
  });

  @override
  State<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends State<VaultLockScreen> {
  String _enteredCode = '';
  String _firstEnteredCode = ''; // For setup confirmation
  bool _isConfirming = false;

  void _onDigitPressed(String digit) {
    if (_enteredCode.length >= 6) return;

    setState(() {
      _enteredCode += digit;
    });

    if (_enteredCode.length == 6) {
      _processCode();
    }
  }

  void _onBackPressed() {
    if (_enteredCode.isEmpty) return;
    setState(() {
      _enteredCode = _enteredCode.substring(0, _enteredCode.length - 1);
    });
  }

  void _processCode() {
    final state = widget.state;
    if (state is VaultSetupRequired) {
      if (!_isConfirming) {
        // First entry done, ask for confirmation
        setState(() {
          _firstEnteredCode = _enteredCode;
          _enteredCode = '';
          _isConfirming = true;
        });
      } else {
        // Confirmation entry done
        if (_enteredCode == _firstEnteredCode) {
          context.read<VaultBloc>().add(SetupVaultPasscodeEvent(_enteredCode));
        } else {
          // Mismatch, reset
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Passcodes do not match. Start over."),
              backgroundColor: Colors.redAccent,
            ),
          );
          setState(() {
            _enteredCode = '';
            _firstEnteredCode = '';
            _isConfirming = false;
          });
        }
      }
    } else if (state is VaultLocked) {
      context.read<VaultBloc>().add(AuthenticatePasscodeEvent(_enteredCode));
      // Clear entered code on submit
      setState(() {
        _enteredCode = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isSetup = state is VaultSetupRequired;
    final isLocked = state is VaultLocked;

    String titleText = "Enter Passcode";
    if (isSetup) {
      titleText = _isConfirming ? "Confirm Passcode" : "Create 6-Digit Passcode";
    }

    final bioAvailable = isLocked && state.isBiometricAvailable;
    final errorMessage = isLocked ? state.errorMessage : null;

    return Scaffold(
      backgroundColor: AppColors.softBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primaryPurple,
              size: 48.sp,
            ),
            UIHelper.verticalSpace(16.h),
            Text(
              titleText,
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            UIHelper.verticalSpace(8.h),
            Text(
              isSetup ? "Secure your private folder with a local code" : "Please enter your security code to proceed",
              style: GoogleFonts.dmSans(
                color: Colors.white38,
                fontSize: 12.sp,
              ),
            ),
            if (errorMessage != null) ...[
              UIHelper.verticalSpace(12.h),
              Text(
                errorMessage,
                style: GoogleFonts.dmSans(
                  color: Colors.redAccent,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            UIHelper.verticalSpace(36.h),

            // Passcode Indicators (6 circles)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final isFilled = index < _enteredCode.length;
                return Container(
                  width: 14.w,
                  height: 14.h,
                  margin: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? AppColors.primaryPurple : Colors.transparent,
                    border: Border.all(
                      color: isFilled ? AppColors.primaryPurple : Colors.white24,
                      width: 1.5.w,
                    ),
                  ),
                );
              }),
            ),
            const Spacer(),

            // Keypad Grid
            Container(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  UIHelper.verticalSpace(16.h),
                  _buildKeypadRow(['4', '5', '6']),
                  UIHelper.verticalSpace(16.h),
                  _buildKeypadRow(['7', '8', '9']),
                  UIHelper.verticalSpace(16.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Biometric button (or empty space)
                      SizedBox(
                        width: 60.w,
                        height: 60.h,
                        child: bioAvailable
                            ? IconButton(
                                icon: Icon(
                                  Icons.fingerprint_rounded,
                                  color: AppColors.primaryPurple,
                                  size: 28.sp,
                                ),
                                onPressed: () {
                                  context.read<VaultBloc>().add(const AuthenticateBiometricEvent());
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      _buildKeypadButton('0'),
                      SizedBox(
                        width: 60.w,
                        height: 60.h,
                        child: IconButton(
                          icon: Icon(
                            Icons.backspace_outlined,
                            color: Colors.white70,
                            size: 20.sp,
                          ),
                          onPressed: _onBackPressed,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            UIHelper.verticalSpace(40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) => _buildKeypadButton(d)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return GestureDetector(
      onTap: () => _onDigitPressed(digit),
      child: Container(
        width: 60.w,
        height: 60.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1.w,
          ),
        ),
        child: Text(
          digit,
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
