import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/gen/assets.gen.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/features/auth/services/cloudinary_service.dart';
import '../../../../helpers/ui_helpers.dart';

class ThemePickerSheet extends StatelessWidget {
  final DocumentReference<Map<String, dynamic>> convRef;
  final Future<void> Function() ensureParticipants;

  const ThemePickerSheet({
    super.key,
    required this.convRef,
    required this.ensureParticipants,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: convRef.snapshots(),
      builder: (streamContext, snapshot) {
        if (snapshot.hasError) {
          debugPrint('🔥 Theme StreamBuilder error: ${snapshot.error}');
        }
        final convData = snapshot.data?.data() ?? {};
        final dbOpacity =
            (convData['themeOpacity'] as num?)?.toDouble() ?? 0.5;
        final currentWallpaper = convData['themeWallpaper'] as String?;
        double? localOpacity;
        bool isUploading = false;

        return StatefulBuilder(
          builder: (builderContext, setModalState) {
            final displayOpacity = localOpacity ?? dbOpacity;

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  UIHelper.verticalSpace(20.h),
                  Text(
                    "Chat Background Theme",
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  UIHelper.verticalSpace(16.h),
                  // Opacity slider
                  Row(
                    children: [
                      Text(
                        "Opacity:",
                        style: GoogleFonts.dmSans(
                            color: Colors.white70, fontSize: 13.sp),
                      ),
                      Expanded(
                        child: Slider(
                          value: displayOpacity,
                          min: 0.0,
                          max: 1.0,
                          activeColor: AppColors.primaryPink,
                          inactiveColor: Colors.white12,
                          onChanged: (val) {
                            setModalState(() {
                              localOpacity = val;
                            });
                          },
                          onChangeEnd: (val) async {
                            await ensureParticipants();
                            convRef.set({
                              'themeOpacity': val,
                            }, SetOptions(merge: true)).catchError((e) {
                              debugPrint('🔥 Failed to write themeOpacity: $e');
                            });
                          },
                        ),
                      ),
                      Text(
                        "${(displayOpacity * 100).toInt()}%",
                        style: GoogleFonts.dmSans(
                            color: Colors.white70, fontSize: 13.sp),
                      ),
                    ],
                  ),
                  UIHelper.verticalSpace(20.h),
                  // Preset options
                  Text(
                    "Select Wallpaper",
                    style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600),
                  ),
                  UIHelper.verticalSpace(12.h),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        // None option
                        GestureDetector(
                          onTap: () async {
                            await ensureParticipants();
                            convRef.set({
                              'themeWallpaper': FieldValue.delete(),
                            }, SetOptions(merge: true)).catchError((e) {
                              debugPrint('🔥 Failed to clear themeWallpaper: $e');
                            });
                          },
                          child: Container(
                            width: 64.w,
                            height: 64.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: currentWallpaper == null
                                    ? AppColors.primaryPink
                                    : Colors.white12,
                                width: currentWallpaper == null ? 2.w : 1.w,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "None",
                                style: GoogleFonts.dmSans(
                                    color: Colors.white54,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                        UIHelper.horizontalSpace(12.w),
                        // Gallery option
                        GestureDetector(
                          onTap: isUploading
                              ? null
                              : () async {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? pickedFile =
                                      await picker.pickImage(
                                    source: ImageSource.gallery,
                                    imageQuality: 85,
                                  );
                                  if (pickedFile == null) return;

                                  setModalState(() {
                                    isUploading = true;
                                  });

                                  try {
                                    final File file = File(pickedFile.path);
                                    final String? uploadedUrl =
                                        await CloudinaryService.uploadImage(
                                            file);
                                    if (uploadedUrl != null &&
                                        uploadedUrl.isNotEmpty) {
                                      await ensureParticipants();
                                      await convRef.set({
                                        'themeWallpaper': uploadedUrl,
                                      }, SetOptions(merge: true));

                                      if (builderContext.mounted) {
                                        AppToast.show(builderContext,
                                            title: "Success",
                                            message:
                                                "Custom wallpaper set successfully!",
                                            type: ToastType.success);
                                      }
                                    } else {
                                      if (builderContext.mounted) {
                                        AppToast.show(builderContext,
                                            title: "Error",
                                            message:
                                                "Failed to upload image.",
                                            type: ToastType.error);
                                      }
                                    }
                                  } catch (e) {
                                    debugPrint('🔥 Failed to set custom wallpaper: $e');
                                    if (builderContext.mounted) {
                                      AppToast.show(builderContext,
                                          title: "Error",
                                          message:
                                              "An unexpected error occurred.",
                                          type: ToastType.error);
                                    }
                                  } finally {
                                    setModalState(() {
                                      isUploading = false;
                                    });
                                  }
                                },
                          child: Container(
                            width: 64.w,
                            height: 64.h,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: currentWallpaper != null &&
                                        currentWallpaper.startsWith('http')
                                    ? AppColors.primaryPink
                                    : Colors.white12,
                                width: currentWallpaper != null &&
                                        currentWallpaper.startsWith('http')
                                    ? 2.w
                                    : 1.w,
                              ),
                            ),
                            child: Center(
                              child: isUploading
                                  ? SizedBox(
                                      width: 20.r,
                                      height: 20.r,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation(
                                            AppColors.primaryPink),
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate_rounded,
                                          color: Colors.white54,
                                          size: 20.sp,
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          "Custom",
                                          style: GoogleFonts.dmSans(
                                              color: Colors.white54,
                                              fontSize: 10.sp,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        UIHelper.horizontalSpace(12.w),
                        _buildPresetThemeOption(
                          url: Assets.images.theme1.path,
                          currentWallpaper: currentWallpaper,
                        ),
                        UIHelper.horizontalSpace(12.w),
                        _buildPresetThemeOption(
                          url: Assets.images.theme2.path,
                          currentWallpaper: currentWallpaper,
                        ),
                        UIHelper.horizontalSpace(12.w),
                        _buildPresetThemeOption(
                          url: Assets.images.theme3.path,
                          currentWallpaper: currentWallpaper,
                        ),
                        UIHelper.horizontalSpace(12.w),
                        _buildPresetThemeOption(
                          url: Assets.images.theme4.path,
                          currentWallpaper: currentWallpaper,
                        ),
                        UIHelper.horizontalSpace(12.w),
                        _buildPresetThemeOption(
                          url: Assets.images.theme5.path,
                          currentWallpaper: currentWallpaper,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetThemeOption(
      {required String url, required String? currentWallpaper}) {
    final isSelected = currentWallpaper == url;
    return GestureDetector(
      onTap: () async {
        await ensureParticipants();
        convRef.set({
          'themeWallpaper': url,
        }, SetOptions(merge: true)).catchError((e) {
          debugPrint('🔥 Failed to write themeWallpaper: $e');
        });
      },
      child: Container(
        width: 64.w,
        height: 64.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink : Colors.transparent,
            width: 2.w,
          ),
          image: DecorationImage(
            image: url.startsWith('http')
                ? CachedNetworkImageProvider(url) as ImageProvider
                : AssetImage(url) as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
