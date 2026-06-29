import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

import '../screens/vault_screen.dart';
import '../screens/bucket_list_screen.dart';
import '../screens/tasks_screen.dart';
import '../screens/love_note_screen.dart';
import 'springy_card.dart';

class QuickActionGrid extends StatelessWidget {
  final double taskProgress;
  final String nextTaskTitle;
  final Function(String note) onSendLoveNote;

  const QuickActionGrid({
    super.key,
    required this.taskProgress,
    required this.nextTaskTitle,
    required this.onSendLoveNote,
  });

  Route _createSlideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  Route _createFadeRoute(Widget page) {
    return PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SpringyCard(
                  onTap: () {
                    Navigator.push(context, _createSlideRoute(const VaultScreen()));
                  },
                  child: _buildGridItem(
                    iconWidget: Hero(
                      tag: "hero-vault-icon",
                      child: Icon(Icons.lock_outline_rounded, color: AppColors.primaryPurple, size: 16.sp),
                    ),
                    iconColor: AppColors.primaryPurple,
                    title: "Vault",
                    subtitle: "Access private shared media",
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: SpringyCard(
                  onTap: () {
                    Navigator.push(context, _createSlideRoute(const BucketListScreen()));
                  },
                  child: _buildGridItem(
                    iconWidget: Hero(
                      tag: "hero-bucket-list-icon",
                      child: Icon(Icons.favorite_border_rounded, color: AppColors.primaryPink, size: 16.sp),
                    ),
                    iconColor: AppColors.primaryPink,
                    title: "Bucket List",
                    subtitle: "Next: Visit Paris 🗼",
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: SpringyCard(
                  onTap: () {
                    Navigator.push(context, _createSlideRoute(const TasksScreen()));
                  },
                  child: _buildGridItem(
                    iconWidget: Hero(
                      tag: "hero-tasks-icon",
                      child: Icon(Icons.checklist_rounded, color: Colors.blueAccent, size: 16.sp),
                    ),
                    iconColor: Colors.blueAccent,
                    title: "Tasks",
                    subtitle: "Next: $nextTaskTitle",
                    progress: taskProgress,
                  ),
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: SpringyCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      _createFadeRoute(
                        LoveNoteScreen(
                          onSend: (note) => onSendLoveNote(note),
                        ),
                      ),
                    );
                  },
                  child: _buildGridItem(
                    iconWidget: Hero(
                      tag: "hero-love-note-icon",
                      child: Icon(Icons.edit_note_rounded, color: Colors.tealAccent, size: 16.sp),
                    ),
                    iconColor: Colors.tealAccent,
                    title: "Love Note",
                    subtitle: "Say something sweet to Babu...",
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem({
    required Widget iconWidget,
    required Color iconColor,
    required String title,
    String? subtitle,
    double? progress,
  }) {
    return Container(
      height: 140.h,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: iconWidget,
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: GoogleFonts.dmSans(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle ?? "",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 11.sp,
                ),
              ),
              if (progress != null) ...[
                UIHelper.verticalSpace(8.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4.h,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  ),
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
