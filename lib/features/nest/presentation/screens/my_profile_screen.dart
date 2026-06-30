import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';

import '../widgets/profile_avatar.dart';
import '../widgets/profile_form_field.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _authService = FirebaseAuthService();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dateController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      try {
        final data = await _authService.getUserProfile(user.uid);
        if (data != null) {
          _nameController.text = data['name'] ?? user.displayName ?? '';
          _nicknameController.text = data['nickname'] ?? '';
          _dateController.text = data['relationshipStartDate'] ?? '';
        } else {
          _nameController.text = user.displayName ?? '';
        }
      } catch (_) {
        _nameController.text = user.displayName ?? '';
      }
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2025, 2, 14),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryPink,
              onPrimary: Colors.white,
              surface: AppColors.navBgColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      setState(() {
        _dateController.text = "${months[picked.month - 1]} ${picked.day}, ${picked.year}";
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _authService.updateUserProfile(
          user.uid,
          name: _nameController.text.trim(),
          nickname: _nicknameController.text.trim(),
          relationshipStartDate: _dateController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20.sp),
                  SizedBox(width: 8.w),
                  const Text("Profile changes saved!"),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to save changes: $e"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBlack,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -80.h,
            left: -50.w,
            child: Container(
              width: 250.w,
              height: 250.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [AppColors.primaryPurple.withValues(alpha: 0.1), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    child: Column(
                      children: [
                        ProfileAvatar(onTap: () => _saveProfile()),
                        UIHelper.verticalSpace(32.h),
                        ProfileFormField(label: "DISPLAY NAME", controller: _nameController, hint: "Enter your display name"),
                        UIHelper.verticalSpace(16.h),
                        ProfileFormField(label: "NICKNAME (your partner sees this)", controller: _nicknameController, hint: "Enter nickname"),
                        UIHelper.verticalSpace(16.h),
                        ProfileFormField(label: "EMAIL", controller: _emailController, enabled: false),
                        UIHelper.verticalSpace(16.h),
                        GestureDetector(
                          onTap: _selectDate,
                          child: AbsorbPointer(
                            child: ProfileFormField(
                              label: "RELATIONSHIP START DATE",
                              controller: _dateController,
                              suffixIcon: Icon(Icons.calendar_today_rounded, color: Colors.white30, size: 16.sp),
                            ),
                          ),
                        ),
                        UIHelper.verticalSpace(32.h),
                        GestureDetector(
                          onTap: _saveProfile,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.primaryPink, AppColors.primaryPurple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Text("Save Changes", style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        UIHelper.verticalSpace(24.h),

                        // Link to Account & Pairing Screen
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, Routes.accountPairingScreen),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.w),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Account & Pairing",
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white70,
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: Colors.white38,
                                  size: 20.sp,
                                ),
                              ],
                            ),
                          ),
                        ),
                        UIHelper.verticalSpace(40.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
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
                border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1.w),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16.sp),
            ),
          ),
          SizedBox(width: 16.w),
          Text("My Profile", style: GoogleFonts.dmSans(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
