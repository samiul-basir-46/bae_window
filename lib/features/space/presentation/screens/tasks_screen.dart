import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final List<Map<String, dynamic>> _tasks = [
    {
      "id": "1",
      "title": "Book dinner table",
      "assignedTo": "Babu",
      "completed": false
    },
    {
      "id": "2",
      "title": "Buy grocery items",
      "assignedTo": "You",
      "completed": false
    },
    {
      "id": "3",
      "title": "Water the plants",
      "assignedTo": "You",
      "completed": false
    },
    {
      "id": "4",
      "title": "Plan weekend movie night",
      "assignedTo": "Babu",
      "completed": true
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addNewTask() {
    final taskController = TextEditingController();
    String assigned = "You";

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: AppColors.navBgColor,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.r)),
            title: Text(
              "Create Task",
              style: GoogleFonts.dmSans(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: taskController,
                  style: GoogleFonts.dmSans(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Task Description",
                    labelStyle: GoogleFonts.dmSans(color: Colors.white38),
                    enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white12)),
                    focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.blueAccent)),
                  ),
                ),
                UIHelper.verticalSpace(16.h),
                Text("Assign To:",
                    style: GoogleFonts.dmSans(
                        color: Colors.white38, fontSize: 11.sp)),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => setModalState(() => assigned = "You"),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: assigned == "You"
                              ? Colors.blueAccent.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: assigned == "You"
                                ? Colors.blueAccent
                                : Colors.white.withValues(alpha: 0.1),
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          "You",
                          style: GoogleFonts.dmSans(
                            color: assigned == "You"
                                ? Colors.blueAccent
                                : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () => setModalState(() => assigned = "Babu"),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: assigned == "Babu"
                              ? Colors.blueAccent.withValues(alpha: 0.15)
                              : Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: assigned == "Babu"
                                ? Colors.blueAccent
                                : Colors.white.withValues(alpha: 0.1),
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          "Babu",
                          style: GoogleFonts.dmSans(
                            color: assigned == "Babu"
                                ? Colors.blueAccent
                                : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text("Cancel",
                    style: GoogleFonts.dmSans(color: Colors.white54)),
              ),
              TextButton(
                onPressed: () {
                  final text = taskController.text.trim();
                  if (text.isNotEmpty) {
                    setState(() {
                      _tasks.add({
                        "id": DateTime.now().millisecondsSinceEpoch.toString(),
                        "title": text,
                        "assignedTo": assigned,
                        "completed": false,
                      });
                    });
                    Navigator.pop(dialogContext);
                  }
                },
                child: Text(
                  "Create",
                  style: GoogleFonts.dmSans(
                      color: Colors.blueAccent, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _tasks.length;
    final completedCount = _tasks.where((t) => t["completed"]).length;
    final progress = total == 0 ? 0.0 : completedCount / total;

    final activeTasks = _tasks.where((t) => !t["completed"]).toList();
    final completedTasks = _tasks.where((t) => t["completed"]).toList();

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
                _buildTopProgressBar(progress, completedCount, total),
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

  Widget _buildTopProgressBar(double progress, int completed, int total) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Shared Progress",
                  style: GoogleFonts.dmSans(
                      color: Colors.white70,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  "$completed/$total Completed (${(progress * 100).toInt()}%)",
                  style: GoogleFonts.dmSans(
                      color: Colors.blueAccent,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            UIHelper.verticalSpace(10.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6.h,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
            ),
          ],
        ),
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

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding:
          EdgeInsets.only(left: 24.w, right: 24.w, top: 8.h, bottom: 120.h),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final id = task["id"]!;

        return Dismissible(
          key: Key(id),
          direction: DismissDirection.horizontal,
          background: _buildSwipeBg(Alignment.centerLeft, Colors.green,
              Icons.check_circle_outline_rounded),
          secondaryBackground: _buildSwipeBg(Alignment.centerRight,
              Colors.redAccent, Icons.delete_outline_rounded),
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {
              setState(() {
                final foundIndex = _tasks.indexWhere((t) => t["id"] == id);
                if (foundIndex != -1) {
                  _tasks[foundIndex]["completed"] = true;
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Task marked as completed!"),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else {
              setState(() {
                _tasks.removeWhere((t) => t["id"] == id);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Task deleted."),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: _buildTaskCard(task),
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

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final String assigned = task["assignedTo"]!;
    final bool completed = task["completed"];

    final Color avatarColor =
        assigned == "You" ? AppColors.primaryPink : AppColors.primaryPurple;

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
      child: Row(
        children: [
          CircleAvatar(
            radius: 16.r,
            backgroundColor: avatarColor.withValues(alpha: 0.15),
            child: Text(
              assigned[0],
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
              task["title"]!,
              style: GoogleFonts.dmSans(
                color: completed ? Colors.white30 : Colors.white,
                fontSize: 13.sp,
                decoration: completed ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Icon(
            completed
                ? Icons.check_circle_rounded
                : Icons.radio_button_off_rounded,
            color: completed ? Colors.greenAccent : Colors.white24,
            size: 18.sp,
          ),
        ],
      ),
    );
  }
}
