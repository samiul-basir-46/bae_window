import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'export_memories_screen.dart';

class NestScreen extends StatelessWidget {
  const NestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBlack,
      body: Stack(
        children: [
          // Background glow highlights to match theme
          Positioned(
            top: -50.h,
            right: -50.w,
            child: Container(
              width: 250.w,
              height: 250.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryPink.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100.h,
            left: -50.w,
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

          // Main Scroll Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Header
                  Text(
                    "Nest",
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  UIHelper.verticalSpace(4.h),
                  Text(
                    "Your Private Control Center",
                    style: GoogleFonts.dmSans(
                      color: Colors.white38,
                      fontSize: 12.sp,
                    ),
                  ),
                  UIHelper.verticalSpace(24.h),

                  // Couple Connection Card
                  _buildCoupleCard(),
                  UIHelper.verticalSpace(24.h),

                  // Section Title
                  Text(
                    "SECURITY & PREFERENCES",
                    style: GoogleFonts.dmSans(
                      color: Colors.white38,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  UIHelper.verticalSpace(12.h),

                  // Option Menu
                  _buildMenuCard(context),
                  UIHelper.verticalSpace(24.h),

                  // Footnote App version
                  Center(
                    child: Text(
                      "BAE Window v1.0.0",
                      style: GoogleFonts.dmSans(
                        color: Colors.white12,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                  UIHelper.verticalSpace(100.h), // Extra space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoupleCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1.w,
        ),
      ),
      child: Row(
        children: [
          // Avatars / Circle Indicator
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24.r,
                backgroundColor: AppColors.primaryPink.withValues(alpha: 0.2),
                child: Icon(Icons.person_rounded, color: AppColors.primaryPink, size: 24.sp),
              ),
              Positioned(
                left: 28.w,
                child: CircleAvatar(
                  radius: 24.r,
                  backgroundColor: AppColors.primaryPurple.withValues(alpha: 0.2),
                  child: Icon(Icons.favorite_rounded, color: AppColors.primaryPurple, size: 20.sp),
                ),
              ),
            ],
          ),
          SizedBox(width: 44.w), // Space for stacked avatars
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Samiul & Bae",
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                UIHelper.verticalSpace(4.h),
                Text(
                  "Connected since Oct 2024",
                  style: GoogleFonts.dmSans(
                    color: Colors.white38,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Text(
              "Active",
              style: GoogleFonts.dmSans(
                color: Colors.greenAccent,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1.w,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Column(
          children: [
            _buildMenuItem(
              icon: Icons.lock_outline_rounded,
              iconColor: AppColors.primaryPurple,
              title: "Vault Passcode Settings",
              subtitle: "Change or reset your 4-digit PIN",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Passcode settings coming soon!"),
                    backgroundColor: AppColors.primaryPurple,
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.download_done_rounded,
              iconColor: AppColors.primaryPink,
              title: "Export Memories",
              subtitle: "Download backup of photos & notes",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ExportMemoriesScreen(),
                  ),
                );
              },
            ),
            _buildDivider(),
            _buildMenuItem(
              icon: Icons.notifications_none_rounded,
              iconColor: Colors.blueAccent,
              title: "Push Notifications",
              subtitle: "Manage memory reminders",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Notification settings coming soon!"),
                    backgroundColor: Colors.blueAccent,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 20.sp),
      ),
      title: Text(
        title,
        style: GoogleFonts.dmSans(
          color: Colors.white,
          fontSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.dmSans(
          color: Colors.white38,
          fontSize: 11.sp,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: Colors.white24,
        size: 20.sp,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1.h,
      thickness: 1.h,
      color: Colors.white.withValues(alpha: 0.05),
      indent: 60.w,
      endIndent: 20.w,
    );
  }
}
