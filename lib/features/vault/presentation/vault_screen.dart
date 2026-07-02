import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

import '../bloc/vault_bloc.dart';
import '../bloc/vault_event.dart';
import '../bloc/vault_state.dart';
import 'vault_lock_screen.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VaultBloc>(
      create: (context) => VaultBloc()..add(const CheckVaultStatusEvent()),
      child: const VaultLifecycleWrapper(),
    );
  }
}

class VaultLifecycleWrapper extends StatefulWidget {
  const VaultLifecycleWrapper({super.key});

  @override
  State<VaultLifecycleWrapper> createState() => _VaultLifecycleWrapperState();
}

class _VaultLifecycleWrapperState extends State<VaultLifecycleWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!mounted) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Instantly hide contents behind a secure overlay for app switcher protection
      context.read<VaultBloc>().add(const HideVaultEvent());
    } else if (state == AppLifecycleState.resumed) {
      // Re-trigger locks when resuming from background
      context.read<VaultBloc>().add(const LockVaultEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Guarantee Vault is locked immediately on exit
        context.read<VaultBloc>().add(const LockVaultEvent());
      },
      child: BlocBuilder<VaultBloc, VaultState>(
        builder: (context, state) {
          if (state is VaultInitial) {
            return const Scaffold(
              backgroundColor: AppColors.softBlack,
              body: Center(
                child: BaeLoader(),
              ),
            );
          } else if (state is VaultSetupRequired || state is VaultLocked) {
            return VaultLockScreen(state: state);
          } else if (state is VaultBackgroundHidden) {
            // Protected secure black placeholder for switcher preview
            return const Scaffold(
              backgroundColor: Colors.black,
              body: SizedBox.shrink(),
            );
          } else if (state is VaultAuthSuccess || state is VaultAuthenticating) {
            return const VaultContentView();
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class VaultContentView extends StatefulWidget {
  const VaultContentView({super.key});

  @override
  State<VaultContentView> createState() => _VaultContentViewState();
}

class _VaultContentViewState extends State<VaultContentView> {
  String _selectedFilter = "All";

  final List<Map<String, String>> _mediaItems = [
    {"type": "photo", "url": "assets/images/placeholder_1.png", "date": "TODAY"},
    {"type": "photo", "url": "assets/images/placeholder_2.png", "date": "TODAY"},
    {"type": "video", "url": "assets/images/placeholder_3.png", "date": "TODAY"},
    {"type": "photo", "url": "assets/images/placeholder_4.png", "date": "YESTERDAY"},
    {"type": "video", "url": "assets/images/placeholder_5.png", "date": "YESTERDAY"},
    {"type": "photo", "url": "assets/images/placeholder_6.png", "date": "1 WEEK AGO"},
  ];

  void _uploadNewMedia() {
    AppToast.show(
      context,
      title: "Upload",
      message: "Select photos/videos from gallery...",
      type: ToastType.info,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<VaultBloc>().state;
    if (state is VaultAuthenticating) {
      return const Scaffold(
        backgroundColor: AppColors.softBlack,
        body: Center(
          child: BaeLoader(),
        ),
      );
    }

    final filteredMedia = _mediaItems.where((item) {
      if (_selectedFilter == "All") return true;
      if (_selectedFilter == "Photos") return item["type"] == "photo";
      if (_selectedFilter == "Videos") return item["type"] == "video";
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.softBlack,
      body: Stack(
        children: [
          // Background Glow (Purple)
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
                    AppColors.primaryPurple.withValues(alpha: 0.15),
                    Colors.transparent,
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
                UIHelper.verticalSpace(16.h),
                _buildFilterBar(),
                UIHelper.verticalSpace(20.h),
                Expanded(
                  child: filteredMedia.isEmpty
                      ? _buildEmptyState()
                      : _buildGridSection(filteredMedia),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 40.h,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _uploadNewMedia,
                backgroundColor: AppColors.primaryPurple,
                elevation: 10,
                child: Icon(Icons.add_rounded, color: Colors.white, size: 28.sp),
              ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 16.sp),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: "hero-vault-icon",
                child: Icon(Icons.lock_outline_rounded, color: AppColors.primaryPurple, size: 20.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                "Secure Vault",
                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          // Explicit Lock Button
          GestureDetector(
            onTap: () {
              context.read<VaultBloc>().add(const LockVaultEvent());
            },
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Icon(Icons.lock_rounded, color: Colors.redAccent.withValues(alpha: 0.8), size: 16.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final filters = ["All", "Photos", "Videos"];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 12.w),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryPurple.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelected ? AppColors.primaryPurple.withValues(alpha: 0.4) : Colors.white12,
                ),
              ),
              child: Text(
                filter,
                style: GoogleFonts.dmSans(
                  color: isSelected ? Colors.white : Colors.white38,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, color: Colors.white24, size: 48.sp),
          UIHelper.verticalSpace(16.h),
          Text(
            "No private moments here yet",
            style: GoogleFonts.dmSans(color: Colors.white38, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildGridSection(List<Map<String, String>> media) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(left: 24.w, right: 24.w, top: 8.h, bottom: 120.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8.h,
        crossAxisSpacing: 8.w,
        childAspectRatio: 1.0,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final item = media[index];
        final isVideo = item["type"] == "video";

        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Display placeholder images or network pictures
                Image.asset(
                  item["url"]!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.white.withValues(alpha: 0.02),
                      child: Icon(Icons.broken_image_outlined, color: Colors.white12, size: 24.sp),
                    );
                  },
                ),
                if (isVideo)
                  Center(
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: const BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20.sp),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
