import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/common_widgets/custom_auth_button.dart';
import 'package:bea_window_app/common_widgets/custom_auth_text_field.dart';
import 'package:bea_window_app/helpers/all_routes.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../bloc/auth_event.dart';
import '../widgets/auth_background_blobs.dart';
import '../widgets/auth_header.dart';
import '../bloc/auth_bloc.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';

class PairingScreen extends StatefulWidget {
  const PairingScreen({super.key});

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _generatedCode;
  String? _errorMessage;
  StreamSubscription? _pairingSub;
  bool _hasNavigated = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));

    _startPairingStatusListener();
  }

  void _startPairingStatusListener() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _pairingSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data();
          if (data != null && data['pairStatus'] == 'paired' && mounted) {
            if (_hasNavigated) return;
            _hasNavigated = true;
            _showPairingSuccessSnackbar();
            Navigator.of(context).pushReplacementNamed(Routes.navigationScreen);
          }
        }
      });
    }
  }

  void _showPairingSuccessSnackbar() {
    if (mounted) {
      AppToast.show(
        context,
        title: "Paired",
        message: "Successfully paired! Welcome to your private space ✦",
        type: ToastType.success,
      );
    }
  }

  @override
  void dispose() {
    _pairingSub?.cancel();
    _tabController.dispose();
    _codeController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _generateCode() {
    context.read<AuthBloc>().add(const GenerateInviteCodeRequested());
  }

  void _joinWithCode() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(JoinWithCodeRequested(_codeController.text.trim().toUpperCase()));
    }
  }

  void _skipPairing() {
    context.read<AuthBloc>().add(const SkipPairingRequested());
  }

  void _copyToClipboard(String code) {
    Clipboard.setData(ClipboardData(text: code));
    AppToast.show(
      context,
      title: "Copied",
      message: "Invite code copied to clipboard!",
      type: ToastType.success,
    );
  }

  void _shareCode(String code) {
    SharePlus.instance.share(
      ShareParams(text: "Hey! Pair with me on Bae Window using this invite code: $code ✦"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is PairingInProgress) {
          setState(() {
            _errorMessage = null;
          });
        } else if (state is PairingCodeGenerated) {
          setState(() {
            _generatedCode = state.code;
          });
        } else if (state is PairingSuccess) {
          if (mounted && !_hasNavigated) {
            _hasNavigated = true;
            _showPairingSuccessSnackbar();
            Navigator.pushReplacementNamed(context, Routes.navigationScreen);
          }
        } else if (state is PairingSkipped) {
          if (mounted && !_hasNavigated) {
            _hasNavigated = true;
            Navigator.pushReplacementNamed(context, Routes.navigationScreen);
          }
        } else if (state is PairingFailure) {
          setState(() {
            _errorMessage = state.errorMessage;
          });
        }
      },
      builder: (context, state) {
        final isLoading = state is PairingInProgress;

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          UIHelper.verticalSpace(36.h),
                          const AuthHeader(
                            logoIcon: Icons.favorite_border_rounded,
                            eyebrow: 'Connect with Partner',
                            headline: 'Pair your\nwindows ✦',
                            subtitle: 'Share your unique invite code with your partner or enter their code to synchronize your experiences.',
                          ),
                          UIHelper.verticalSpace(24.h),
                          _buildTabBar(),
                          UIHelper.verticalSpace(28.h),
                          SizedBox(
                            height: 250.h,
                            child: TabBarView(
                              controller: _tabController,
                              physics: const NeverScrollableScrollPhysics(),
                              children: [
                                _buildCreateCodeTab(isLoading),
                                _buildEnterCodeTab(isLoading),
                              ],
                            ),
                          ),
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
                          UIHelper.verticalSpace(20.h),
                          GestureDetector(
                            onTap: isLoading ? null : _skipPairing,
                            child: Text(
                              "Skip for now",
                              style: GoogleFonts.dmSans(
                                color: const Color(0xFF9090A8),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          UIHelper.verticalSpace(24.h),
                        ],
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

  Widget _buildTabBar() {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: const Color(0xFF8060C8),
          borderRadius: BorderRadius.circular(14.r),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF9090A8),
        labelStyle: GoogleFonts.dmSans(fontSize: 13.sp, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(text: 'Create Code'),
          Tab(text: 'Enter Code'),
        ],
      ),
    );
  }

  Widget _buildCreateCodeTab(bool isLoading) {
    if (_generatedCode != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Share this code with your partner:",
            style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 13.sp),
          ),
          UIHelper.verticalSpace(16.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              _generatedCode!,
              style: GoogleFonts.dmSans(
                color: const Color(0xFFE295B5),
                fontSize: 32.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
          ),
          UIHelper.verticalSpace(20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                onPressed: () => _copyToClipboard(_generatedCode!),
                tooltip: 'Copy Code',
              ),
              SizedBox(width: 24.w),
              IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.white70),
                onPressed: () => _shareCode(_generatedCode!),
                tooltip: 'Share Code',
              ),
            ],
          ),
          UIHelper.verticalSpace(12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                    const BaeLoader(
                      isFullScreen: false,
                      size: 14.0,
                    ),
              SizedBox(width: 8.w),
              Text(
                "Waiting for partner to join...",
                style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 12.sp),
              ),
            ],
          ),
        ],
      );
    }

    return Center(
      child: CustomAuthButton(
        label: 'Generate Invite Code',
        isLoading: isLoading,
        onTap: _generateCode,
      ),
    );
  }

  Widget _buildEnterCodeTab(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomAuthTextField(
            controller: _codeController,
            hintText: 'Partner\'s Invite Code',
            prefixIcon: Icons.qr_code_rounded,
            keyboardType: TextInputType.text,
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Invite code is required';
              }
              if (val.trim().length != 6) {
                return 'Code must be exactly 6 characters';
              }
              return null;
            },
          ),
          UIHelper.verticalSpace(28.h),
          CustomAuthButton(
            label: 'Join Partner',
            isLoading: isLoading,
            onTap: _joinWithCode,
          ),
        ],
      ),
    );
  }
}
