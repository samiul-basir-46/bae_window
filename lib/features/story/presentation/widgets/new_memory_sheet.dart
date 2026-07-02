import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';

class NewMemorySheet extends StatefulWidget {
  final Function({
    required String title,
    required String note,
    required String imageUrl,
    required bool isMilestone,
    required bool isPrivate,
    required String layoutType,
  }) onAdd;

  const NewMemorySheet({super.key, required this.onAdd});

  @override
  State<NewMemorySheet> createState() => _NewMemorySheetState();
}

class _NewMemorySheetState extends State<NewMemorySheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  String _imageUrl = "https://images.unsplash.com/photo-1518199266791-5375a83190b7?auto=format&fit=crop&q=80&w=500";
  bool _isMilestone = false;
  bool _isPrivate = false;
  String _layoutType = "full";

  final List<String> _mockImages = [
    "https://images.unsplash.com/photo-1518199266791-5375a83190b7?auto=format&fit=crop&q=80&w=500",
    "https://images.unsplash.com/photo-1490730141103-6cac27aaab94?auto=format&fit=crop&q=80&w=500",
    "https://images.unsplash.com/photo-1469474968028-56623f02e42e?auto=format&fit=crop&q=80&w=500",
    "https://images.unsplash.com/photo-1447752875215-b2761acb3c5d?auto=format&fit=crop&q=80&w=500",
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: AppColors.navBgColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.w,
        ),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 5.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                UIHelper.verticalSpace(24.h),
                Text(
                  "Add New Memory",
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                UIHelper.verticalSpace(20.h),
                // Title Input
                _buildTextField(
                  controller: _titleController,
                  label: "Title",
                  hint: "Rooftop sunset, Coffee date...",
                ),
                UIHelper.verticalSpace(16.h),
                // Note Input
                _buildTextField(
                  controller: _noteController,
                  label: "Note / Description",
                  hint: "Write down your thoughts...",
                  maxLines: 3,
                ),
                UIHelper.verticalSpace(16.h),
                // Image selection (Mock)
                Text(
                  "Select Cover Image",
                  style: GoogleFonts.dmSans(
                    color: Colors.white70,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                UIHelper.verticalSpace(8.h),
                SizedBox(
                  height: 80.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _mockImages.length,
                    itemBuilder: (context, index) {
                      final img = _mockImages[index];
                      final isSelected = _imageUrl == img;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _imageUrl = img;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 12.w),
                          width: 80.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected ? AppColors.primaryPink : Colors.transparent,
                              width: 2.w,
                            ),
                            image: DecorationImage(
                              image: NetworkImage(img),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                UIHelper.verticalSpace(20.h),
                // Options Switches
                _buildSwitchOption(
                  title: "Mark as Milestone",
                  subtitle: "Highlighted with a gold border in your feed",
                  value: _isMilestone,
                  onChanged: (val) {
                    setState(() {
                      _isMilestone = val;
                      if (val) _isPrivate = false; // Cannot be milestone and private at same time
                    });
                  },
                ),
                UIHelper.verticalSpace(12.h),
                _buildSwitchOption(
                  title: "Add to Private Vault",
                  subtitle: "Requires biometric or PIN authentication to view",
                  value: _isPrivate,
                  onChanged: (val) {
                    setState(() {
                      _isPrivate = val;
                      if (val) _isMilestone = false;
                    });
                  },
                ),
                UIHelper.verticalSpace(12.h),
                // Layout selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Layout Style",
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Choose full-width or half-width grid card",
                          style: GoogleFonts.dmSans(
                            color: Colors.white38,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildLayoutButton("full", Icons.splitscreen_rounded),
                        SizedBox(width: 8.w),
                        _buildLayoutButton("grid", Icons.grid_view_rounded),
                      ],
                    ),
                  ],
                ),
                UIHelper.verticalSpace(90.h), // Spacing for action button
              ],
            ),
          ),
          // Save Button
          Positioned(
            left: 24.w,
            right: 24.w,
            bottom: 24.h,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                onPressed: () {
                  if (_titleController.text.trim().isEmpty) {
                    AppToast.show(
                      context,
                      title: "Required",
                      message: "Please enter a title",
                      type: ToastType.error,
                    );
                    return;
                  }
                  widget.onAdd(
                    title: _titleController.text.trim(),
                    note: _noteController.text.trim(),
                    imageUrl: _imageUrl,
                    isMilestone: _isMilestone,
                    isPrivate: _isPrivate,
                    layoutType: _layoutType,
                  );
                  Navigator.pop(context);
                },
                child: Text(
                  "Create Memory",
                  style: GoogleFonts.dmSans(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: Colors.white70,
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        UIHelper.verticalSpace(8.h),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(color: Colors.white24, fontSize: 14.sp),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: const BorderSide(color: AppColors.primaryPink),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchOption({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.dmSans(
                  color: Colors.white38,
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primaryPink,
          activeTrackColor: AppColors.primaryPink.withValues(alpha: 0.3),
        ),
      ],
    );
  }

  Widget _buildLayoutButton(String type, IconData icon) {
    final isSelected = _layoutType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _layoutType = type;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryPink.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryPink.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
            width: 1.w,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primaryPink : Colors.white54,
          size: 18.sp,
        ),
      ),
    );
  }
}
