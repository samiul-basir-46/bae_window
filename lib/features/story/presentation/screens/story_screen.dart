import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../bloc/story_bloc.dart';
import '../bloc/story_event.dart';
import '../bloc/story_state.dart';
import '../widgets/new_memory_sheet.dart';
import '../widgets/month_group_feed.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';
import 'package:bea_window_app/common_widgets/bae_loader.dart';
import 'package:bea_window_app/common_widgets/floating_bubbles_background.dart';
import 'package:bea_window_app/helpers/all_routes.dart';

class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StoryScreenView();
  }
}

class StoryScreenView extends StatefulWidget {
  const StoryScreenView({super.key});

  @override
  State<StoryScreenView> createState() => _StoryScreenViewState();
}

class _StoryScreenViewState extends State<StoryScreenView> {
  bool _isSearching = false;
  String _searchQuery = "";

  String? _coupleId;
  String? _currentUserUid;
  String _myNickname = "You";
  String _partnerNickname = "Bae";
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndWatch();
  }

  Future<void> _loadProfileAndWatch() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserUid = user.uid;
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          _coupleId = data['pairId'] as String?;
          _myNickname = data['nickname'] as String? ?? "You";

          final pUid = await _getPartnerUid(_coupleId);
          if (pUid != null) {
            final partnerDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(pUid)
                .get();
            if (partnerDoc.exists && partnerDoc.data() != null) {
              _partnerNickname =
                  partnerDoc.data()!['nickname'] as String? ?? "Bae";
            }
          }
        }
      }

      if (mounted && _coupleId != null) {
        context.read<StoryBloc>().add(LoadStoriesEvent(
              coupleId: _coupleId!,
              currentUserUid: _currentUserUid!,
              currentUserName: _myNickname,
              partnerName: _partnerNickname,
              forceRefresh: false, // Reads from cache first to save database costs
            ));
      }
    } catch (e) {
      debugPrint("Error loading story profile: $e");
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

  void _openNewMemorySheet(BuildContext context) {
    if (_coupleId == null) {
      AppToast.show(
        context,
        title: "Unpaired",
        message: "Connect with your partner first to share memories!",
        type: ToastType.error,
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => NewMemorySheet(
        onAdd: ({
          required String title,
          required String note,
          String? imageUrl,
          dynamic imageFile,
          required bool isMilestone,
          required String layoutType,
        }) {
          context.read<StoryBloc>().add(AddMemoryEvent(
                title: title,
                note: note,
                imageUrl: imageUrl,
                imageFile: imageFile,
                isMilestone: isMilestone,
                layoutType: layoutType,
              ));
        },
      ),
    );
  }

  void _showContextMenu(BuildContext context, MemoryItem memory) {
    final storyBloc = context.read<StoryBloc>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          topRight: Radius.circular(28.r),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
            color: AppColors.navBgColor.withValues(alpha: 0.95),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 5.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                UIHelper.verticalSpace(20.h),
                Text(
                  memory.title,
                  style: GoogleFonts.dmSans(
                    color: Colors.white70,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                UIHelper.verticalSpace(16.h),
                _buildContextOption(
                  icon: Icons.edit_note_rounded,
                  label: "Edit Note",
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showEditNoteDialog(context, storyBloc, memory);
                  },
                ),
                _buildContextOption(
                  icon: Icons.delete_outline_rounded,
                  label: "Delete Memory",
                  textColor: Colors.redAccent,
                  iconColor: Colors.redAccent,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    storyBloc.add(DeleteMemoryEvent(memory.id));
                  },
                ),
                UIHelper.verticalSpace(12.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditNoteDialog(
      BuildContext context, StoryBloc bloc, MemoryItem memory) {
    final controller = TextEditingController(text: memory.note);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.navBgColor,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text(
          "Edit Note",
          style: GoogleFonts.dmSans(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: GoogleFonts.dmSans(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.primaryPink),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text("Cancel",
                style: GoogleFonts.dmSans(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              bloc.add(EditMemoryNoteEvent(
                  id: memory.id, newNote: controller.text.trim()));
              Navigator.pop(dialogContext);
            },
            child: Text("Save",
                style: GoogleFonts.dmSans(
                    color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildContextOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color textColor = Colors.white70,
    Color iconColor = Colors.white60,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        label,
        style: GoogleFonts.dmSans(color: textColor, fontSize: 14.sp),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softBlack,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100.h,
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
          Positioned(
            bottom: 50.h,
            right: -100.w,
            child: Container(
              width: 350.w,
              height: 350.h,
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
          
          // Content
          SafeArea(
            child: _loadingProfile
                ? const Center(child: BaeLoader())
                : (_coupleId == null
                    ? _buildUnpairedState()
                    : BlocBuilder<StoryBloc, StoryState>(
                        builder: (context, state) {
                          if (state is StoryLoading) {
                            return const Center(child: BaeLoader());
                          } else if (state is StoryLoaded) {
                            List<MemoryItem> filteredMemories = [];

                            if (state.selectedFilter == StoryFilter.all) {
                              filteredMemories = state.memories.toList();
                            } else if (state.selectedFilter == StoryFilter.milestones) {
                              filteredMemories = state.memories
                                  .where((m) => m.isMilestone)
                                  .toList();
                            }

                            // Search query filter
                            if (_searchQuery.isNotEmpty) {
                              filteredMemories = filteredMemories
                                  .where((m) =>
                                      m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                                      m.note.toLowerCase().contains(_searchQuery.toLowerCase()))
                                  .toList();
                            }

                            // Group by Month/Year
                            final grouped = <String, List<MemoryItem>>{};
                            for (var memory in filteredMemories) {
                              final parts = memory.dateString.split(" ");
                              if (parts.length >= 3) {
                                final monthYear =
                                    "${parts[0].toUpperCase()} ${parts[2]}";
                                grouped
                                    .putIfAbsent(monthYear, () => [])
                                    .add(memory);
                              } else {
                                grouped
                                    .putIfAbsent("OTHER", () => [])
                                    .add(memory);
                              }
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top Bar
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24.w, vertical: 16.h),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (_isSearching)
                                        Expanded(
                                          child: Container(
                                            height: 40.h,
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 16.w),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.05),
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              border: Border.all(
                                                color: Colors.white
                                                    .withValues(alpha: 0.08),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.search_rounded,
                                                    color: Colors.white30,
                                                    size: 18.sp),
                                                SizedBox(width: 8.w),
                                                Expanded(
                                                  child: TextField(
                                                    autofocus: true,
                                                    style: GoogleFonts.dmSans(
                                                        color: Colors.white,
                                                        fontSize: 14.sp),
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          "Search memories...",
                                                      hintStyle:
                                                          GoogleFonts.dmSans(
                                                              color: Colors
                                                                  .white30),
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                                    onChanged: (val) {
                                                      setState(() {
                                                        _searchQuery =
                                                            val.trim();
                                                      });
                                                    },
                                                  ),
                                                ),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _isSearching = false;
                                                      _searchQuery = "";
                                                    });
                                                  },
                                                  child: Icon(
                                                      Icons.close_rounded,
                                                      color: Colors.white54,
                                                      size: 18.sp),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )
                                      else ...[
                                        Text(
                                          "Our Story",
                                          style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontSize: 24.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            _buildIconButton(
                                                Icons.search_rounded, () {
                                              setState(() {
                                                _isSearching = true;
                                              });
                                            }),
                                            SizedBox(width: 12.w),
                                            _buildIconButton(Icons.add_rounded,
                                                () => _openNewMemorySheet(context)),
                                          ],
                                        ),
                                      ]
                                    ],
                                  ),
                                ),

                                // Filter tabs
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 24.w, vertical: 8.h),
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: [
                                        _buildFilterTab(
                                            "All Memories",
                                            StoryFilter.all,
                                            state.selectedFilter,
                                            context),
                                        SizedBox(width: 10.w),
                                        _buildFilterTab(
                                            "Milestones",
                                            StoryFilter.milestones,
                                            state.selectedFilter,
                                            context),
                                      ],
                                    ),
                                  ),
                                ),

                                // Feed list
                                Expanded(
                                  child: filteredMemories.isEmpty
                                      ? _buildEmptyState()
                                      : _buildMemoriesList(grouped),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      )),
          ),
          
          // Floating Action Button
          if (!_loadingProfile && _coupleId != null)
            Positioned(
              right: 24.w,
              bottom: 124.h,
              child: GestureDetector(
                onTap: () => _openNewMemorySheet(context),
                child: Container(
                  width: 56.w,
                  height: 56.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryPink, AppColors.primaryPurple],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPink.withValues(alpha: 0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 26.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1.w,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white70,
          size: 20.sp,
        ),
      ),
    );
  }

  Widget _buildFilterTab(
    String label,
    StoryFilter filter,
    StoryFilter selectedFilter,
    BuildContext context,
  ) {
    final isSelected = selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        context.read<StoryBloc>().add(ChangeFilterEvent(filter));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPink.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPink.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.05),
            width: 1.w,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            color: isSelected ? AppColors.primaryPink : Colors.white54,
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined,
              color: Colors.white24, size: 48.sp),
          UIHelper.verticalSpace(16.h),
          Text(
            "No Memories Yet",
            style: GoogleFonts.dmSans(
                color: Colors.white54,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold),
          ),
          UIHelper.verticalSpace(4.h),
          Text(
            "Create your first shared memory together!",
            style: GoogleFonts.dmSans(color: Colors.white24, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildUnpairedState() {
    return FloatingBubblesBackground(
      bubbleColor: AppColors.primaryPink,
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(24.r),
                decoration: BoxDecoration(
                  color: AppColors.primaryPink.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primaryPink.withValues(alpha: 0.15),
                    width: 2.w,
                  ),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primaryPink,
                  size: 48.sp,
                ),
              ),
              UIHelper.verticalSpace(32.h),
              Text(
                "Shared Memory Lane",
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              UIHelper.verticalSpace(12.h),
              Text(
                "Connect with your partner to start uploading pictures, saving notes, and tracking your relationship milestones together in a shared timeline.",
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  color: Colors.white54,
                  fontSize: 13.sp,
                  height: 1.5,
                ),
              ),
              UIHelper.verticalSpace(40.h),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, Routes.accountPairingScreen);
                },
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryPurple, AppColors.primaryPink],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPink.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.link_rounded, color: Colors.white, size: 18.sp),
                      SizedBox(width: 8.w),
                      Text(
                        "Pair with Partner",
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemoriesList(Map<String, List<MemoryItem>> grouped) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
          left: 24.w,
          right: 24.w,
          top: 16.h,
          bottom: 120.h),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final key = grouped.keys.elementAt(index);
        final items = grouped[key]!;
        return MonthGroupFeed(
          month: key,
          items: items,
          onCardLongPress: (memory) =>
              _showContextMenu(context, memory),
        );
      },
    );
  }
}
