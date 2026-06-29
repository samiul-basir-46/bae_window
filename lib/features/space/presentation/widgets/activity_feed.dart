import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import '../bloc/space_state.dart';

class ActivityFeed extends StatelessWidget {
  final List<MomentItem> moments;

  const ActivityFeed({
    super.key,
    required this.moments,
  });

  @override
  Widget build(BuildContext context) {
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
        child: ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          itemCount: moments.length,
          separatorBuilder: (context, index) => Divider(
            height: 1.h,
            thickness: 1.h,
            color: Colors.white.withValues(alpha: 0.05),
            indent: 20.w,
            endIndent: 20.w,
          ),
          itemBuilder: (context, index) {
            final moment = moments[index];
            IconData icon = Icons.circle_notifications_rounded;
            Color iconColor = Colors.white38;

            if (moment.type == 'vault') {
              icon = Icons.lock_outline_rounded;
              iconColor = AppColors.primaryPurple;
            } else if (moment.type == 'task') {
              icon = Icons.checklist_rounded;
              iconColor = Colors.blueAccent;
            } else if (moment.type == 'note') {
              icon = Icons.edit_note_rounded;
              iconColor = Colors.tealAccent;
            }

            return ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
              leading: Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 14.sp),
              ),
              title: RichText(
                text: TextSpan(
                  style: GoogleFonts.dmSans(fontSize: 12.sp),
                  children: [
                    TextSpan(
                      text: "${moment.user} ",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: moment.action,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              trailing: Text(
                moment.time,
                style: GoogleFonts.dmSans(
                  color: Colors.white24,
                  fontSize: 10.sp,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
