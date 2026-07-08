import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';
import 'package:bea_window_app/helpers/all_routes.dart';

import '../widgets/unpair_dialog.dart';
import '../widgets/delete_account_dialogs.dart';
import '../widgets/sensitive_warning_card.dart';
import '../widgets/action_card.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';

class AccountPairingScreen extends StatefulWidget {
  const AccountPairingScreen({super.key});

  @override
  State<AccountPairingScreen> createState() => _AccountPairingScreenState();
}

class _AccountPairingScreenState extends State<AccountPairingScreen> {
  final String _userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

  void _showUnpairDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => UnpairDialog(
        onConfirm: (password) => _handleUnpair(password),
      ),
    );
  }

  Future<void> _handleUnpair(String password) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: BaeLoader()),
    );

    try {
      await FirebaseAuthService().unpairCouple(password);
      if (mounted) Navigator.pop(context); // Pop loading spinner

      if (mounted) {
        AppToast.show(
          context,
          title: "Account Action",
          message: "You have unpaired from Bae.",
          type: ToastType.success,
        );
        Navigator.pop(context); // Go back to NestScreen
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Pop loading spinner

      if (mounted) {
        AppToast.show(
          context,
          title: "Verification Failed",
          message: "Incorrect password. Please try again.",
          type: ToastType.error,
        );
      }
    }
  }

  void _showDeleteAccountFlow() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => DeleteAccountVerifyDialog(
        email: _userEmail,
        onVerify: (password) => _showDeleteAccountConfirmDialog(password),
      ),
    );
  }

  void _showDeleteAccountConfirmDialog(String password) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => DeleteAccountConfirmDialog(
        onDeleteForever: () => _handleDeleteAccount(password),
      ),
    );
  }

  Future<void> _handleDeleteAccount(String password) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: BaeLoader()),
    );

    try {
      await FirebaseAuthService().deleteUserAccount(password);
      if (mounted) Navigator.pop(context); // Pop loading spinner

      if (mounted) {
        AppToast.show(
          context,
          title: "Account Deleted",
          message: "Your account has been deleted permanently.",
          type: ToastType.success,
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.loginScreen,
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Pop loading spinner

      if (mounted) {
        AppToast.show(
          context,
          title: "Action Failed",
          message: "Incorrect password or failed to delete account. Please try again.",
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBlack,
      body: Stack(
        children: [
          Positioned(
            top: -100.h,
            right: -50.w,
            child: Container(
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF5252).withValues(alpha: 0.06),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                UIHelper.verticalSpace(24.h),
                const SensitiveWarningCard(),
                UIHelper.verticalSpace(32.h),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    children: [
                      ActionCard(
                        icon: Icons.heart_broken_rounded,
                        iconColor: const Color(0xFFFF5252),
                        title: "Unpair from Bae",
                        subtitle:
                            "Shared memories, tasks, and bucket list will be removed for both of you",
                        onTap: _showUnpairDialog,
                      ),
                      UIHelper.verticalSpace(20.h),
                      ActionCard(
                        icon: Icons.delete_outline_rounded,
                        iconColor: Colors.grey,
                        title: "Delete My Account",
                        subtitle:
                            "Your account and all linked data will be permanently erased",
                        onTap: _showDeleteAccountFlow,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
            "Account & Pairing",
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
