import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';

class ExportMemoriesScreen extends StatefulWidget {
  const ExportMemoriesScreen({super.key});

  @override
  State<ExportMemoriesScreen> createState() => _ExportMemoriesScreenState();
}

class _ExportMemoriesScreenState extends State<ExportMemoriesScreen> {
  bool _isPdfSelected = true;
  bool _isExporting = false;
  String _lastExported = "Never";

  void _triggerExport() async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isExporting = false;
        final now = DateTime.now();
        _lastExported = "${now.day}/${now.month}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
      });

      AppToast.show(
        context,
        title: "Export Sent",
        message: "Export request sent! We'll email you the download link.",
        type: ToastType.success,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1.w,
              ),
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white70,
              size: 16.sp,
            ),
          ),
        ),
        title: Text(
          "Export Memories",
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned(
            top: 40.h,
            left: -80.w,
            child: Container(
              width: 300.w,
              height: 300.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryPurple.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                        width: 1.w,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Format",
                          style: GoogleFonts.dmSans(
                            color: Colors.white70,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        UIHelper.verticalSpace(16.h),

                        Row(
                          children: [
                            Expanded(
                              child: _buildFormatPill(
                                label: "PDF + Photos",
                                isSelected: _isPdfSelected,
                                onTap: () => setState(() => _isPdfSelected = true),
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _buildFormatPill(
                                label: "ZIP Archive",
                                isSelected: !_isPdfSelected,
                                onTap: () => setState(() => _isPdfSelected = false),
                              ),
                            ),
                          ],
                        ),
                        UIHelper.verticalSpace(28.h),

                        GestureDetector(
                          onTap: _triggerExport,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(vertical: 16.h),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isExporting
                                    ? [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.1)]
                                    : [AppColors.primaryPink, AppColors.primaryPurple],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: _isExporting
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: AppColors.primaryPink.withValues(alpha: 0.25),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: _isExporting
                                ? BaeLoader(
                                    isFullScreen: false,
                                    size: 20.h,
                                  )
                                : Text(
                                    "Export & Email to Me",
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        UIHelper.verticalSpace(14.h),

                        Text(
                          "This may take a few minutes to prepare. We'll email you a download link once it's ready.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            color: Colors.white38,
                            fontSize: 11.sp,
                            height: 1.4,
                          ),
                        ),
                        UIHelper.verticalSpace(20.h),

                        Center(
                          child: Text(
                            "Last exported: $_lastExported",
                            style: GoogleFonts.dmSans(
                              color: Colors.white24,
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPink.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPink
                : Colors.white.withValues(alpha: 0.05),
            width: 1.5.w,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: isSelected ? Colors.white : Colors.white38,
            fontSize: 13.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
