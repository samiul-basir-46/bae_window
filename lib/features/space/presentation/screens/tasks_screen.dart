import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/features/space_screen/services/realtime_sync_service.dart';
import '../bloc/task_notification_cubit.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';
import 'package:bea_window_app/helpers/notification_service.dart';

import '../widgets/task_progress_bar.dart';
import '../widgets/task_card.dart';
import '../widgets/create_task_dialog.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskNotificationCubit(),
      child: const _TasksView(),
    );
  }
}

class _TasksView extends StatefulWidget {
  const _TasksView();

  @override
  State<_TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<_TasksView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final RealtimeSyncService _syncService = RealtimeSyncService();

  String? _coupleId;
  String? _partnerUid;
  String _myNickname = "You";
  String _partnerNickname = "Babu";
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          _coupleId = data['pairId'] as String?;
          _myNickname = data['nickname'] as String? ?? "You";

          final pUid = await _getPartnerUid(_coupleId);
          _partnerUid = pUid;
          if (pUid != null) {
            final partnerDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(pUid)
                .get();
            if (partnerDoc.exists && partnerDoc.data() != null) {
              _partnerNickname =
                  partnerDoc.data()!['nickname'] as String? ?? "Babu";
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) {
        setState(() {
          _loadingProfile = false;
        });
      }
    }
  }

  Future<String?> _getPartnerUid(String? coupleId) async {
    if (coupleId == null) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('couples')
        .doc(coupleId)
        .get();
    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    final user1 = data['user1Uid'] as String?;
    final user2 = data['user2Uid'] as String?;

    if (user1 == user.uid) return user2;
    if (user2 == user.uid) return user1;
    return null;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addNewTask() {
    if (_coupleId == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (dialogContext) => CreateTaskDialog(
        partnerNickname: _partnerNickname,
        onCreate: (text, assigned) async {
          Navigator.pop(dialogContext);

          final user = FirebaseAuth.instance.currentUser;
          final creatorUid = user?.uid ?? "";
          final creatorName = _myNickname;

          final assignedToUid = (assigned == "You") ? creatorUid : (_partnerUid ?? "");
          final assignedToName = (assigned == "You") ? _myNickname : _partnerNickname;
          final status = (assigned == "You") ? "inProgress" : "pending";

          await _syncService.addTask(
            coupleId: _coupleId!,
            title: text,
            creatorUid: creatorUid,
            creatorName: creatorName,
            assignedToUid: assignedToUid,
            assignedToName: assignedToName,
            status: status,
          );

          await _syncService.addMoment(
            _coupleId!,
            user: _myNickname,
            action: "created a task: $text",
            type: "task",
          );

          if (assigned != "You") {
            unawaited(PushNotificationService.sendNotificationToPartner(
              title: "New Task Assigned ✦",
              body: "A new task has been assigned to you: $text",
              type: "tasks",
            ));
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingProfile) {
      return const Scaffold(
        backgroundColor: AppColors.softBlack,
        body: Center(
          child: BaeLoader(),
        ),
      );
    }

    if (_coupleId == null) {
      return Scaffold(
        backgroundColor: AppColors.softBlack,
        body: Center(
          child: Text(
            "You must be paired to access tasks",
            style: GoogleFonts.dmSans(color: Colors.white70),
          ),
        ),
      );
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _syncService.watchTasks(_coupleId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: AppColors.softBlack,
            body: Center(
              child: BaeLoader(),
            ),
          );
        }

        final tasks = snapshot.data!;
        final total = tasks.length;
        final completedCount =
            tasks.where((t) => t["status"] == "completed").length;
        final progress = total == 0 ? 0.0 : completedCount / total;

        final activeTasks = tasks.where((t) => t["status"] != "completed").toList();
        final completedTasks =
            tasks.where((t) => t["status"] == "completed").toList();

        return Scaffold(
          backgroundColor: AppColors.softBlack,
          body: Stack(
            children: [
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
                        Colors.blueAccent.withValues(alpha: 0.12),
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
                    UIHelper.verticalSpace(12.h),
                    TaskProgressBar(
                      progress: progress,
                      completed: completedCount,
                      total: total,
                    ),
                    UIHelper.verticalSpace(16.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: TabBar(
                        controller: _tabController,
                        indicatorColor: Colors.blueAccent,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white38,
                        dividerColor: Colors.white.withValues(alpha: 0.05),
                        labelStyle: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold, fontSize: 13.sp),
                        tabs: const [
                          Tab(text: "Active"),
                          Tab(text: "Completed"),
                        ],
                      ),
                    ),
                    UIHelper.verticalSpace(12.h),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTaskList(activeTasks),
                          _buildTaskList(completedTasks),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 40.h,
                left: 24.w,
                right: 24.w,
                child: GestureDetector(
                  onTap: _addNewTask,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.blueAccent, AppColors.primaryPurple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueAccent.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      "+ Create New Task",
                      style: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: "hero-tasks-icon",
                child: Icon(Icons.checklist_rounded,
                    color: Colors.blueAccent, size: 20.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                "Tasks Dashboard",
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(width: 24.w),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Map<String, dynamic>> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Text(
          "No Tasks in this section",
          style: GoogleFonts.dmSans(color: Colors.white24, fontSize: 12.sp),
        ),
      );
    }

    final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding:
          EdgeInsets.only(left: 24.w, right: 24.w, top: 8.h, bottom: 120.h),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final id = task["id"]!;
        final String status = task["status"] ?? "pending";
        final String title = task["title"] ?? "";

        return Dismissible(
          key: Key(id),
          direction: DismissDirection.endToStart, // Swipe left to delete
          background: _buildSwipeBg(Alignment.centerRight,
              Colors.redAccent, Icons.delete_outline_rounded),
          confirmDismiss: (direction) async {
            if (status == "pending") {
              if (context.mounted) {
                AppToast.show(
                  context,
                  title: "Cannot Delete",
                  message: "Pending tasks cannot be deleted.",
                  type: ToastType.error,
                );
              }
              return false;
            }

            await _syncService.deleteTask(_coupleId!, id);
            unawaited(PushNotificationService.sendNotificationToPartner(
              title: "Task Deleted ✗",
              body: "$_myNickname deleted the task: \"$title\"",
              type: "tasks",
            ));
            if (context.mounted) {
              AppToast.show(
                context,
                title: "Task Deleted",
                message: "Task deleted successfully.",
                type: ToastType.error,
              );
            }
            return true;
          },
          child: TaskCard(
            task: task,
            currentUserUid: currentUserUid,
            coupleId: _coupleId!,
            myNickname: _myNickname,
            syncService: _syncService,
          ),
        );
      },
    );
  }

  Widget _buildSwipeBg(Alignment alignment, Color color, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      alignment: alignment,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Icon(icon, color: color, size: 22.sp),
    );
  }
}
