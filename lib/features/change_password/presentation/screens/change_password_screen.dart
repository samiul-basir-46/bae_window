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
import 'package:bea_window_app/common_widgets/bae_loader.dart';

class ChangePasswordScreen extends StatelessWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

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
                                controller: oldPasswordController,
                                hint: "Enter your current password",
                                errorText: oldPwError,
                              ),
                              UIHelper.verticalSpace(20.h),
                              PasswordInputField(
                                label: "NEW PASSWORD",
                                controller: newPasswordController,
                                hint: "Enter a strong new password",
                                errorText: newPwError,
                              ),
                              UIHelper.verticalSpace(20.h),
                              PasswordInputField(
                                label: "CONFIRM PASSWORD",
                                controller: confirmPasswordController,
                                hint: "Re-enter your new password",
                                errorText: confirmPwError,
                              ),
                              UIHelper.verticalSpace(40.h),

                              // Submit Button
                              GestureDetector(
                                onTap: isLoading
                                    ? null
                                    : () {
                                        context.read<ChangePasswordBloc>().add(
                                              SubmitChangePasswordEvent(
                                                oldPassword:
                                                    oldPasswordController.text,
                                                newPassword:
                                                    newPasswordController.text,
                                                confirmPassword:
                                                    confirmPasswordController
                                                        .text,
                                              ),
                                            );
                                      },
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF6E7F),
                                        Color(0xFFBFE9FF)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF6E7F)
                                            .withValues(alpha: 0.15),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: isLoading
                                      ? BaeLoader(
                                          isFullScreen: false,
                                          size: 20.sp,
                                        )
                                      : Text(
                                          "Update Password",
                                          style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
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
