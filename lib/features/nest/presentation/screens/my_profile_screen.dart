import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bea_window_app/features/auth/services/firebase_auth_service.dart';
import 'package:bea_window_app/features/auth/services/cloudinary_service.dart';

import '../widgets/profile_avatar.dart';
import '../widgets/profile_form_field.dart';
import 'package:bea_window_app/common_widgets/custom_date_picker.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _authService = FirebaseAuthService();
  final _imagePicker = ImagePicker();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dateController = TextEditingController();

  String? _avatarUrl;
  String? _gender;
  bool _isLoading = true;
  bool _isUploadingAvatar = false;
  bool _isSaving = false;
  bool _isDateDirty = false;
  File? _localAvatarFile;
  StreamSubscription? _profileSubscription;

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
          _avatarUrl = data['profilePicture'];
          _gender = data['gender'];
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

      if (user != null) {
        _listenToProfile(user.uid);
      }
    }
  }

  void _listenToProfile(String uid) {
    _profileSubscription?.cancel();
    _profileSubscription = _authService.userStream(uid).listen((snapshot) {
      if (!mounted || _isDateDirty) return;

      final latestDate =
          snapshot.data()?['relationshipStartDate'] as String? ?? '';
      if (_dateController.text != latestDate) {
        _dateController.text = latestDate;
      }
    });
  }

  @override
  void dispose() {
    _profileSubscription?.cancel();
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await CustomDatePicker.show(
      context,
      initialDate: DateTime(2025, 2, 14),
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec"
      ];
      setState(() {
        _dateController.text =
            "${months[picked.month - 1]} ${picked.day}, ${picked.year}";
        _isDateDirty = true;
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (picked == null) return;

      final localFile = File(picked.path);

      setState(() {
        _localAvatarFile = localFile; // সাথে সাথে local file দেখানো শুরু
        _isUploadingAvatar = true;
      });

      final uploadedUrl = await CloudinaryService.uploadImage(localFile);

      if (uploadedUrl != null) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await _authService.updateUserProfile(
            user.uid,
            avatarUrl: uploadedUrl,
          );
        }
        if (mounted) {
          setState(() {
            _avatarUrl = uploadedUrl;
            _isUploadingAvatar = false;
            // _localAvatarFile রেখে দিচ্ছি যাতে নেটওয়ার্ক ছবি load হওয়ার আগ পর্যন্ত local ছবিই দেখা যায়
          });
          AppToast.show(
            context,
            title: "Success",
            message: "Profile picture updated!",
            type: ToastType.success,
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _isUploadingAvatar = false;
            _localAvatarFile =
                null; 
          });
          AppToast.show(
            context,
            title: "Failed",
            message: "Failed to upload profile picture. Try again.",
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
          _localAvatarFile = null;
        });
        AppToast.show(
          context,
          title: "Error",
          message: "Error picking image: $e",
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await _authService.updateUserProfile(
        user.uid,
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        relationshipStartDate: _dateController.text.trim(),
        gender: _gender,
      );

      if (mounted) {
        _isDateDirty = false;
        AppToast.show(
          context,
          title: "Saved",
          message: "Profile changes saved!",
          type: ToastType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        AppToast.show(
          context,
          title: "Failed",
          message: "Failed to save changes: $e",
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
                  colors: [
                    AppColors.primaryPurple.withValues(alpha: 0.1),
                    Colors.transparent
                  ],
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
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    child: Column(
                      children: [
                        ProfileAvatar(
                          avatarUrl: _avatarUrl,
                          localFile: _localAvatarFile,
                          isUploading: _isUploadingAvatar,
                          onTap: _pickAndUploadAvatar,
                        ),
                        UIHelper.verticalSpace(32.h),
                        ProfileFormField(
                            label: "DISPLAY NAME",
                            controller: _nameController,
                            hint: "Enter your display name"),
                        UIHelper.verticalSpace(16.h),
                        ProfileFormField(
                            label: "NICKNAME (your partner sees this)",
                            controller: _nicknameController,
                            hint: "Enter nickname"),
                        UIHelper.verticalSpace(16.h),
                        _buildGenderSelector(),
                        UIHelper.verticalSpace(16.h),
                        ProfileFormField(
                            label: "EMAIL",
                            controller: _emailController,
                            enabled: false),
                        UIHelper.verticalSpace(16.h),
                        GestureDetector(
                          onTap: _selectDate,
                          child: AbsorbPointer(
                            child: ProfileFormField(
                              label: "RELATIONSHIP START DATE",
                              controller: _dateController,
                              suffixIcon: Icon(Icons.calendar_today_rounded,
                                  color: Colors.white30, size: 16.sp),
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
                                colors: [
                                  AppColors.primaryPink,
                                  AppColors.primaryPurple
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Text("Save Changes",
                                style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                        UIHelper.verticalSpace(24.h),

                        // Link to Account & Pairing Screen
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, Routes.accountPairingScreen),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 16.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  width: 1.w),
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
          if (_isLoading || _isSaving)
            const Center(
              child: BaeLoader(),
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
          Text("My Profile",
              style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 8.h),
          child: Text(
            "GENDER",
            style: GoogleFonts.dmSans(
              color: Colors.white38,
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Male Card
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _gender = 'male';
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: _gender == 'male'
                        ? const Color(0xFF8060C8).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: _gender == 'male'
                          ? const Color(0xFF8060C8)
                          : Colors.white.withValues(alpha: 0.05),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.male_rounded,
                        color: _gender == 'male'
                            ? const Color(0xFFA58DE3)
                            : Colors.white38,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Male',
                        style: GoogleFonts.dmSans(
                          color: _gender == 'male'
                              ? Colors.white
                              : Colors.white38,
                          fontSize: 13.sp,
                          fontWeight: _gender == 'male'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            // Female Card
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _gender = 'female';
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 52.h,
                  decoration: BoxDecoration(
                    color: _gender == 'female'
                        ? const Color(0xFFFF8FB8).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: _gender == 'female'
                          ? const Color(0xFFFF8FB8)
                          : Colors.white.withValues(alpha: 0.05),
                      width: 1.w,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.female_rounded,
                        color: _gender == 'female'
                            ? const Color(0xFFFF8FB8)
                            : Colors.white38,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'Female',
                        style: GoogleFonts.dmSans(
                          color: _gender == 'female'
                              ? Colors.white
                              : Colors.white38,
                          fontSize: 13.sp,
                          fontWeight: _gender == 'female'
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
