import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../bloc/story_bloc.dart';
import '../bloc/story_event.dart';
import '../bloc/story_state.dart';
import '../widgets/new_memory_sheet.dart';
import '../widgets/vault_setup_sheet.dart';
import '../widgets/pin_unlock_dialog.dart';
import '../widgets/memory_card.dart';
import '../widgets/month_group_feed.dart';

class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StoryBloc>(
      create: (context) => StoryBloc()..add(const LoadMemoriesEvent()),
      child: const StoryScreenView(),
    );
  }
}

class StoryScreenView extends StatefulWidget {
  const StoryScreenView({super.key});

  @override
  State<StoryScreenView> createState() => _StoryScreenViewState();
}

class _StoryScreenViewState extends State<StoryScreenView> {
  void _openNewMemorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => NewMemorySheet(
        onAdd: ({
          required String title,
          required String note,
          required String imageUrl,
          required bool isMilestone,
          required bool isPrivate,
          required String layoutType,
        }) {
          context.read<StoryBloc>().add(AddMemoryEvent(
                title: title,
                note: note,
                imageUrl: imageUrl,
                isMilestone: isMilestone,
                isPrivate: isPrivate,
                layoutType: layoutType,
              ));
        },
      ),
    );
  }

  void _showPINDialog(BuildContext context, String correctPin, bool isBiometricsEnabled) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (dialogContext) => PINUnlockDialog(
        correctPin: correctPin,
        isBiometricsEnabled: isBiometricsEnabled,
        onSuccess: () {
          context.read<StoryBloc>().add(const UnlockVaultEvent());
        },
      ),
    );
  }

  void _showSetupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => VaultSetupSheet(
        onSetup: (pin, enableBiometrics) {
          context.read<StoryBloc>().add(SetupVaultPinEvent(
                pin: pin,
                enableBiometrics: enableBiometrics,
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
                  icon: memory.isPrivate
                      ? Icons.lock_open_rounded
                      : Icons.lock_rounded,
                  label: memory.isPrivate
                      ? "Move to Feed (Make Public)"
                      : "Move to Private Vault",
                  onTap: () {
                    Navigator.pop(sheetContext);
                    storyBloc.add(MoveToVaultEvent(
                        id: memory.id, isPrivate: !memory.isPrivate));
                  },
                ),
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
          // Content Scroll View
          SafeArea(
            child: BlocBuilder<StoryBloc, StoryState>(
              builder: (context, state) {
                if (state is StoryLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
                    ),
                  );
                } else if (state is StoryLoaded) {
                  // Filter memories
                  List<MemoryItem> filteredMemories = [];
                  if (state.selectedFilter == StoryFilter.all) {
                    filteredMemories =
                        state.memories.where((m) => !m.isPrivate).toList();
                  } else if (state.selectedFilter == StoryFilter.milestones) {
                    filteredMemories = state.memories
                        .where((m) => m.isMilestone && !m.isPrivate)
                        .toList();
                  } else if (state.selectedFilter == StoryFilter.vault) {
                    if (state.isVaultUnlocked) {
                      filteredMemories =
                          state.memories.where((m) => m.isPrivate).toList();
                    }
                  }

                  // Group memories by Month/Year
                  final grouped = <String, List<MemoryItem>>{};
                  for (var memory in filteredMemories) {
                    final parts = memory.dateString.split(" ");
                    if (parts.length >= 3) {
                      final monthYear = "${parts[0].toUpperCase()} ${parts[2]}";
                      grouped.putIfAbsent(monthYear, () => []).add(memory);
                    } else {
                      grouped.putIfAbsent("OTHER", () => []).add(memory);
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                                _buildIconButton(Icons.search_rounded, () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text("Search feature coming soon!"),
                                      backgroundColor: AppColors.primaryPink,
                                    ),
                                  );
                                }),
                                SizedBox(width: 12.w),
                                _buildIconButton(Icons.add_rounded,
                                    () => _openNewMemorySheet(context)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 24.w, vertical: 8.h),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildFilterTab("All Memories", StoryFilter.all,
                                  state.selectedFilter, context),
                              SizedBox(width: 10.w),
                              _buildFilterTab(
                                  "Milestones",
                                  StoryFilter.milestones,
                                  state.selectedFilter,
                                  context),
                              SizedBox(width: 10.w),
                              _buildFilterTab(
                                  "Private Vault",
                                  StoryFilter.vault,
                                  state.selectedFilter,
                                  context),
                            ],
                          ),
                        ),
                      ),
                      // Biometrics Toggle Setting when Vault is Unlocked
                      if (state.selectedFilter == StoryFilter.vault && state.isVaultUnlocked) ...[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.fingerprint_rounded, color: AppColors.primaryPink, size: 16.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    "Biometric Unlock",
                                    style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13.sp, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Switch(
                                value: state.isBiometricsEnabled,
                                onChanged: (val) {
                                  context.read<StoryBloc>().add(ToggleBiometricsEvent(val));
                                },
                                activeThumbColor: AppColors.primaryPink,
                                activeTrackColor: AppColors.primaryPink.withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                      // Memory Feed Scroll Area
                      Expanded(
                        child: state.selectedFilter == StoryFilter.vault &&
                                !state.isVaultUnlocked
                            ? _buildLockedVaultPrompt(context, state)
                            : filteredMemories.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    physics: const BouncingScrollPhysics(),
                                    padding: EdgeInsets.only(
                                        left: 24.w,
                                        right: 24.w,
                                        top: 16.h,
                                        bottom: 120.h),
                                    itemCount: grouped.keys.length +
                                        (state.selectedFilter == StoryFilter.all
                                            ? 1
                                            : 0),
                                    itemBuilder: (context, index) {
                                      if (index == grouped.keys.length) {
                                        return PrivateVaultEntryCard(
                                          isUnlocked: state.isVaultUnlocked,
                                          onTap: () {
                                            if (state.vaultPin == null) {
                                              _showSetupSheet(context);
                                            } else if (!state.isVaultUnlocked) {
                                              _showPINDialog(context, state.vaultPin!, state.isBiometricsEnabled);
                                            } else {
                                              context.read<StoryBloc>().add(
                                                  const ChangeFilterEvent(
                                                      StoryFilter.vault));
                                            }
                                          },
                                        );
                                      }

                                      final key = grouped.keys.elementAt(index);
                                      final items = grouped[key]!;
                                      return MonthGroupFeed(
                                        month: key,
                                        items: items,
                                        onCardLongPress: (memory) =>
                                            _showContextMenu(context, memory),
                                      );
                                    },
                                  ),
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          // Floating Action Button
          Positioned(
            right: 24.w,
            bottom: 100.h,
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

  Widget _buildLockedVaultPrompt(BuildContext context, StoryLoaded state) {
    final isSetup = state.vaultPin != null;
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryPurple.withValues(alpha: 0.1),
                  width: 2.w,
                ),
              ),
              child: Icon(
                isSetup ? Icons.lock_rounded : Icons.lock_open_outlined,
                color: AppColors.primaryPurple,
                size: 48.sp,
              ),
            ),
            UIHelper.verticalSpace(24.h),
            Text(
              isSetup ? "Private Vault Locked" : "Setup Private Vault",
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            UIHelper.verticalSpace(8.h),
            Text(
              isSetup
                  ? "Access requires biometric or PIN authentication to protect your private memories."
                  : "Secure your private memories with a custom 4-digit PIN.",
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: Colors.white38,
                fontSize: 12.sp,
                height: 1.5,
              ),
            ),
            UIHelper.verticalSpace(28.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: () {
                  if (isSetup) {
                    _showPINDialog(context, state.vaultPin!, state.isBiometricsEnabled);
                  } else {
                    _showSetupSheet(context);
                  }
                },
                child: Text(
                  isSetup ? "Unlock Vault" : "Setup Secure PIN",
                  style: GoogleFonts.dmSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
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
}
