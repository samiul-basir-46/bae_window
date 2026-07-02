import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

import '../bloc/change_password_bloc.dart';
import '../bloc/change_password_event.dart';
import '../bloc/change_password_state.dart';
import '../widgets/password_input_field.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/common_widgets/custom_auth_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final pw = _newPasswordController.text;
    int strength = 0;
    if (pw.length >= 6) strength++;
    if (pw.length >= 10) strength++;
    if (pw.contains(RegExp(r'[A-Z]')) && pw.contains(RegExp(r'[0-9]'))) {
      strength++;
    }
    if (pw.contains(RegExp(r'[!@#\$&*~]'))) strength++;
    setState(() => _passwordStrength = strength);
  }

  Color get _strengthColor {
    if (_passwordStrength <= 1) return const Color(0xFFE060A0);
    if (_passwordStrength == 2) return const Color(0xFFF5A623);
    return const Color(0xFF4CD964);
  }

  String get _strengthLabel {
    if (_passwordStrength == 0) return '';
    if (_passwordStrength <= 1) return 'Weak';
    if (_passwordStrength == 2) return 'Fair';
    if (_passwordStrength == 3) return 'Good';
    return 'Strong ✦';
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChangePasswordBloc(),
      child: Scaffold(
        backgroundColor: AppColors.softBlack,
        body: Stack(
          children: [
            // Background Glows
            Positioned(
              top: -80.h,
              right: -50.w,
              child: Container(
                width: 250.w,
                height: 250.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF6E7F).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: BlocConsumer<ChangePasswordBloc, ChangePasswordState>(
                listener: (context, state) {
                  if (state is ChangePasswordSuccess) {
                    AppToast.show(
                      context,
                      title: "Success",
                      message: "Password changed successfully!",
                      type: ToastType.success,
                    );
                    Navigator.pop(context);
                  } else if (state is ChangePasswordFailure &&
                      state.generalError != null) {
                    AppToast.show(
                      context,
                      title: "Error",
                      message: state.generalError!,
                      type: ToastType.error,
                    );
                  }
                },
                builder: (context, state) {
                  final isLoading = state is ChangePasswordLoading;

                  String? oldPwError;
                  String? newPwError;
                  String? confirmPwError;

                  if (state is ChangePasswordFailure) {
                    oldPwError = state.oldPasswordError;
                    newPwError = state.newPasswordError;
                    confirmPwError = state.confirmPasswordError;
                  }

                  return Column(
                    children: [
                      _buildHeader(context),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24.w, vertical: 16.h),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PasswordInputField(
                                label: "OLD PASSWORD",
                                controller: _oldPasswordController,
                                hint: "Enter your current password",
                                errorText: oldPwError,
                              ),
                              UIHelper.verticalSpace(20.h),
                              PasswordInputField(
                                label: "NEW PASSWORD",
                                controller: _newPasswordController,
                                hint: "Enter a strong new password",
                                errorText: newPwError,
                              ),
                              UIHelper.verticalSpace(10.h),
                              _buildStrengthBar(),
                              UIHelper.verticalSpace(20.h),
                              PasswordInputField(
                                label: "CONFIRM PASSWORD",
                                controller: _confirmPasswordController,
                                hint: "Re-enter your new password",
                                errorText: confirmPwError,
                              ),
                              UIHelper.verticalSpace(40.h),

                              // Submit Button
                              CustomAuthButton(
                                label: 'Update Password',
                                isLoading: isLoading,
                                showArrow: true,
                                onTap: () {
                                  context.read<ChangePasswordBloc>().add(
                                        SubmitChangePasswordEvent(
                                          oldPassword:
                                              _oldPasswordController.text,
                                          newPassword:
                                              _newPasswordController.text,
                                          confirmPassword:
                                              _confirmPasswordController.text,
                                        ),
                                      );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthBar() {
    if (_newPasswordController.text.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 3.h,
                margin: EdgeInsets.only(right: i < 3 ? 4.w : 0),
                decoration: BoxDecoration(
                  color: i < _passwordStrength
                      ? _strengthColor
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            );
          }),
        ),
        if (_strengthLabel.isNotEmpty) ...[
          UIHelper.verticalSpace(6.h),
          Text(
            _strengthLabel,
            style: GoogleFonts.dmSans(
                fontSize: 11.sp,
                color: _strengthColor,
                fontWeight: FontWeight.w500),
          ),
        ]
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05), width: 1.w),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white70, size: 16.sp),
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            "Change Password",
            style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
