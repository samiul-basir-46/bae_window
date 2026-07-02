import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/helpers/notification_service.dart';
import 'package:bea_window_app/features/space_screen/services/realtime_sync_service.dart';
import 'dart:async';

class TaskCard extends StatelessWidget {
  final Map<String, dynamic> task;
  final String currentUserUid;
  final String coupleId;
  final String myNickname;
  final RealtimeSyncService syncService;

  const TaskCard({
    super.key,
    required this.task,
    required this.currentUserUid,
    required this.coupleId,
    required this.myNickname,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    final String status = task["status"] ?? "pending";
    final String assignedToUid = task["assignedToUid"] ?? "";
    final String assignedToName = task["assignedToName"] ?? "Babu";
    final String title = task["title"] ?? "";

    final bool isAssignee = assignedToUid == currentUserUid;

    final Color avatarColor =
        isAssignee ? AppColors.primaryPink : AppColors.primaryPurple;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1.w,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16.r,
                backgroundColor: avatarColor.withValues(alpha: 0.15),
                child: Text(
                  isAssignee ? "Y" : (assignedToName.isNotEmpty ? assignedToName[0] : "B"),
                  style: GoogleFonts.dmSans(
                    color: avatarColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.dmSans(
                    color: status == "completed" ? Colors.white30 : Colors.white,
                    fontSize: 13.sp,
                    decoration: status == "completed" ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              _buildStatusIcon(status),
            ],
          ),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    switch (status) {
      case "completed":
        return Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18.sp);
      case "waitingConfirmation":
        return Icon(Icons.hourglass_empty_rounded, color: Colors.amberAccent, size: 18.sp);
      default:
        return Icon(Icons.radio_button_off_rounded, color: Colors.white24, size: 18.sp);
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    final String status = task["status"] ?? "pending";
    final String assignedToUid = task["assignedToUid"] ?? "";
    final String title = task["title"] ?? "";
    final String id = task["id"]!;

    final bool isAssignee = assignedToUid == currentUserUid;

    // 1. Assignee marks task as done (Pending or In Progress status)
    if ((status == "pending" || status == "inProgress") && isAssignee) {
      return Padding(
        padding: EdgeInsets.only(top: 12.h, left: 48.w),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
            foregroundColor: Colors.blueAccent,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
              side: const BorderSide(color: Colors.blueAccent, width: 1),
            ),
          ),
          onPressed: () async {
            await syncService.updateTask(coupleId, id, {'status': 'waitingConfirmation'});
            await syncService.addMoment(
              coupleId,
              user: myNickname,
              action: "marked a task as completed: $title. Waiting for confirmation.",
              type: "task",
            );
            unawaited(PushNotificationService.sendNotificationToPartner(
              title: "Task Finished ✦",
              body: "$myNickname marked the task \"$title\" as completed. Please verify.",
              type: "tasks",
            ));
            if (context.mounted) {
              AppToast.show(
                context,
                title: "Sent for verification",
                message: "Waiting for partner to verify.",
                type: ToastType.info,
              );
            }
          },
          child: Text(
            "Mark as Done",
            style: GoogleFonts.dmSans(fontSize: 11.sp, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    // 2. Verifier reviews the completed task
    if (status == "waitingConfirmation" && !isAssignee) {
      return Padding(
        padding: EdgeInsets.only(top: 12.h, left: 48.w),
        child: Row(
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent.withValues(alpha: 0.15),
                foregroundColor: Colors.greenAccent,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: const BorderSide(color: Colors.greenAccent, width: 1),
                ),
              ),
              onPressed: () async {
                await syncService.updateTask(coupleId, id, {'status': 'completed'});
                await syncService.addMoment(
                  coupleId,
                  user: myNickname,
                  action: "confirmed completion of task: $title",
                  type: "task",
                );
                unawaited(PushNotificationService.sendNotificationToPartner(
                  title: "Task Confirmed ✓",
                  body: "Your task \"$title\" has been verified and completed.",
                  type: "tasks",
                ));
                if (context.mounted) {
                  AppToast.show(
                    context,
                    title: "Task Confirmed",
                    message: "Completion approved!",
                    type: ToastType.success,
                  );
                }
              },
              child: Text(
                "Confirm Completion",
                style: GoogleFonts.dmSans(fontSize: 10.sp, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 8.w),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                foregroundColor: Colors.redAccent,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                ),
              ),
              onPressed: () async {
                await syncService.updateTask(coupleId, id, {'status': 'inProgress'});
                await syncService.addMoment(
                  coupleId,
                  user: myNickname,
                  action: "rejected completion of task: $title",
                  type: "task",
                );
                unawaited(PushNotificationService.sendNotificationToPartner(
                  title: "Task Rejected ✗",
                  body: "Task completion for \"$title\" was rejected. Please review.",
                  type: "tasks",
                ));
                if (context.mounted) {
                  AppToast.show(
                    context,
                    title: "Task Rejected",
                    message: "Task sent back to partner.",
                    type: ToastType.error,
                  );
                }
              },
              child: Text(
                "Reject",
                style: GoogleFonts.dmSans(fontSize: 10.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    // 3. Status text labels for non-actionable users
    if (status == "waitingConfirmation" && isAssignee) {
      return Padding(
        padding: EdgeInsets.only(top: 8.h, left: 48.w),
        child: Text(
          "Waiting for verification...",
          style: GoogleFonts.dmSans(fontSize: 11.sp, color: Colors.amberAccent, fontStyle: FontStyle.italic),
        ),
      );
    }

    if ((status == "pending" || status == "inProgress") && !isAssignee) {
      return Padding(
        padding: EdgeInsets.only(top: 8.h, left: 48.w),
        child: Text(
          status == "pending" ? "Pending assignee start" : "In progress...",
          style: GoogleFonts.dmSans(fontSize: 11.sp, color: Colors.white38),
        ),
      );
    }

    if (status == "completed") {
      return Padding(
        padding: EdgeInsets.only(top: 8.h, left: 48.w),
        child: Text(
          "Completed ✓",
          style: GoogleFonts.dmSans(fontSize: 11.sp, color: Colors.greenAccent, fontWeight: FontWeight.bold),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
