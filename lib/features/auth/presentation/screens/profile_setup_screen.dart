import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bea_window_app/common_widgets/custom_auth_button.dart';
import 'package:bea_window_app/common_widgets/custom_auth_text_field.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../bloc/auth_event.dart';
import '../widgets/auth_background_blobs.dart';
import '../widgets/auth_header.dart';
import '../bloc/auth_bloc.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _nicknameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

  File? _selectedLocalFile;
  String? _selectedPredefinedUrl;
  String? _errorMessage;
  String? _selectedGender; // 'male' or 'female'

// Male Avatars
  final List<String> _maleAvatars = [
    'https://api.dicebear.com/9.x/adventurer/png?seed=Sophie&backgroundColor=ffd5dc',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Ryan&backgroundColor=c0aede',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Charlie&backgroundColor=ffd5dc',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Mia&backgroundColor=d1f4d1',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Ethan&backgroundColor=d1f4d1',
  ];

  // Female Avatars
  final List<String> _femaleAvatars = [
    'https://api.dicebear.com/9.x/adventurer/png?seed=Felix&backgroundColor=b6e3f4',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Emma&backgroundColor=b6e3f4',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Lily&backgroundColor=c0aede',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Jake&backgroundColor=d1f4d1',
    'https://api.dicebear.com/9.x/adventurer/png?seed=Zoe&backgroundColor=ffdfbf',
  ];

  // Default Avatars
  final List<String> _defaultAvatars = [
    'https://api.dicebear.com/9.x/adventurer-neutral/png?seed=Boy&backgroundColor=b6e3f4',
    'https://api.dicebear.com/9.x/adventurer-neutral/png?seed=Girl&backgroundColor=ffd5dc',
  ];

  List<String> get _currentAvatars {
    if (_selectedGender == 'male') {
      return _maleAvatars;
    } else if (_selectedGender == 'female') {
      return _femaleAvatars;
    } else {
      return _defaultAvatars;
    }
  }

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

    // Default selection
    _selectedPredefinedUrl = _defaultAvatars.first;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null) {
        setState(() {
          _selectedLocalFile = File(picked.path);
          _selectedPredefinedUrl = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to pick image: $e";
      });
    }
  }

  void _onContinue() {
    if (_selectedGender == null) {
      setState(() {
        _errorMessage = "Please select your gender";
      });
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            SaveProfileRequested(
              nickname: _nicknameController.text.trim(),
              avatarUrl: _selectedPredefinedUrl,
              avatarFile: _selectedLocalFile,
              gender: _selectedGender!,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is ProfileSetupLoading) {
          setState(() {
            _errorMessage = null;
          });
        } else if (state is ProfileSetupSuccess) {
          Navigator.pushReplacementNamed(context, Routes.pairingScreen);
        } else if (state is ProfileSetupFailure) {
          setState(() {
            _errorMessage = state.errorMessage;
          });
        }
      },
      builder: (context, state) {
        final isLoading = state is ProfileSetupLoading;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D10),
          body: Stack(
            children: [
              const AuthBackgroundBlobs(),
              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 28.w),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            UIHelper.verticalSpace(40.h),
                            const AuthHeader(
                              logoIcon: Icons.person_outline_rounded,
                              eyebrow: 'Profile Customization',
                              headline: 'Setup your\nprofile ✦',
                              subtitle:
                                  'Choose an avatar or upload your own, and pick a nickname that your partner will see.',
                            ),
                            UIHelper.verticalSpace(28.h),
                            _buildAvatarSelector(),
                            UIHelper.verticalSpace(28.h),
                            CustomAuthTextField(
                              controller: _nicknameController,
                              hintText: 'Your Nickname',
                              prefixIcon: Icons.badge_outlined,
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Nickname is required';
                                }
                                return null;
                              },
                            ),
                            UIHelper.verticalSpace(20.h),
                            _buildGenderSelector(),
                            if (_errorMessage != null) ...[
                              UIHelper.verticalSpace(14.h),
                              Text(
                                _errorMessage!,
                                style: GoogleFonts.dmSans(
                                  color: const Color(0xFFE060A0),
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            UIHelper.verticalSpace(32.h),
                            CustomAuthButton(
                              label: 'Continue',
                              isLoading: isLoading,
                              onTap: _onContinue,
                            ),
                            UIHelper.verticalSpace(24.h),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarSelector() {
    return Column(
      children: [
        Center(
          child: Stack(
            children: [
              Container(
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 2.sp),
                  image: _selectedLocalFile != null
                      ? DecorationImage(
                          image: FileImage(_selectedLocalFile!),
                          fit: BoxFit.cover,
                        )
                      : (_selectedPredefinedUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_selectedPredefinedUrl!),
                              fit: BoxFit.cover,
                            )
                          : null),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickFromGallery,
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: const BoxDecoration(
                      color: Color(0xFF8060C8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        UIHelper.verticalSpace(20.h),
        Text(
          'Or choose a predefined avatar:',
          style: GoogleFonts.dmSans(
            color: Colors.white54,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        UIHelper.verticalSpace(12.h),
        SizedBox(
          height: 52.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemCount: _currentAvatars.length,
            separatorBuilder: (context, index) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final url = _currentAvatars[index];
              final isSelected = _selectedPredefinedUrl == url;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPredefinedUrl = url;
                    _selectedLocalFile = null;
                  });
                },
                child: Container(
                  width: 50.r,
                  height: 50.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8060C8)
                          : Colors.transparent,
                      width: 2.5.sp,
                    ),
                    image: DecorationImage(
                      image: NetworkImage(url),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
          child: Row(
            children: [
              Icon(Icons.wc_rounded, color: Colors.white54, size: 16.sp),
              SizedBox(width: 8.w),
              Text(
                'Gender',
                style: GoogleFonts.dmSans(
                  color: Colors.white70,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
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
                    _selectedGender = 'male';
                    _errorMessage = null;
                    if (_selectedLocalFile == null) {
                      _selectedPredefinedUrl = _maleAvatars.first;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: _selectedGender == 'male'
                        ? const Color(0xFF8060C8).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: _selectedGender == 'male'
                          ? const Color(0xFF8060C8)
                          : Colors.white.withValues(alpha: 0.08),
                      width: _selectedGender == 'male' ? 1.5.sp : 1.sp,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.male_rounded,
                        color: _selectedGender == 'male'
                            ? const Color(0xFFA58DE3)
                            : Colors.white38,
                        size: 24.sp,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Male',
                        style: GoogleFonts.dmSans(
                          color: _selectedGender == 'male'
                              ? Colors.white
                              : Colors.white38,
                          fontSize: 14.sp,
                          fontWeight: _selectedGender == 'male'
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
                    _selectedGender = 'female';
                    _errorMessage = null;
                    if (_selectedLocalFile == null) {
                      _selectedPredefinedUrl = _femaleAvatars.first;
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 60.h,
                  decoration: BoxDecoration(
                    color: _selectedGender == 'female'
                        ? const Color(0xFFFF8FB8).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: _selectedGender == 'female'
                          ? const Color(0xFFFF8FB8)
                          : Colors.white.withValues(alpha: 0.08),
                      width: _selectedGender == 'female' ? 1.5.sp : 1.sp,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.female_rounded,
                        color: _selectedGender == 'female'
                            ? const Color(0xFFFF8FB8)
                            : Colors.white38,
                        size: 24.sp,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'Female',
                        style: GoogleFonts.dmSans(
                          color: _selectedGender == 'female'
                              ? Colors.white
                              : Colors.white38,
                          fontSize: 14.sp,
                          fontWeight: _selectedGender == 'female'
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
