import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';

class NewMemorySheet extends StatefulWidget {
  final Function({
    required String title,
    required String note,
    File? imageFile,
    required List<File> additionalImageFiles,
    required bool isMilestone,
    required String layoutType,
  }) onAdd;

  const NewMemorySheet({super.key, required this.onAdd});

  @override
  State<NewMemorySheet> createState() => _NewMemorySheetState();
}

class _NewMemorySheetState extends State<NewMemorySheet> {
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  File? _selectedImageFile;
  final List<File> _additionalImageFiles = [];
  bool _isMilestone = false;
  String _layoutType = "full";
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 35, // native compression to guarantee absolutely no lag
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: "Error",
          message: "Failed to pick image: $e",
          type: ToastType.error,
        );
      }
    }
  }

  Future<void> _pickAdditionalImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        imageQuality: 35, // native compression to guarantee absolutely no lag
      );
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _additionalImageFiles.addAll(pickedFiles.map((x) => File(x.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          title: "Error",
          message: "Failed to pick additional images: $e",
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
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
              padding: EdgeInsets.only(
                  left: 24.w, right: 24.w, top: 24.h, bottom: 120.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Center(
                        child: Container(
                          width: 40.w,
                          height: 5.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
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

                  // Image Picker Container (Optimized with ResizeImage preview to eliminate lag)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 180.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.02),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 1.w,
                        ),
                        image: _selectedImageFile != null
                            ? DecorationImage(
                                image: ResizeImage(
                                    FileImage(_selectedImageFile!),
                                    width: 250,
                                    height: 250),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _selectedImageFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryPink
                                        .withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_photo_alternate_rounded,
                                    color: AppColors.primaryPink,
                                    size: 28.sp,
                                  ),
                                ),
                                UIHelper.verticalSpace(12.h),
                                Text(
                                  "Add Thumbnail Picture",
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                UIHelper.verticalSpace(4.h),
                                Text(
                                  "Tap to browse gallery",
                                  style: GoogleFonts.dmSans(
                                    color: Colors.white30,
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            )
                          : Stack(
                              children: [
                                Positioned(
                                  top: 12.h,
                                  right: 12.w,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedImageFile = null;
                                        _additionalImageFiles.clear();
                                      });
                                    },
                                    child: Container(
                                      padding: EdgeInsets.all(6.w),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close_rounded,
                                        color: Colors.white,
                                        size: 16.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  if (_selectedImageFile != null) ...[
                    UIHelper.verticalSpace(16.h),
                    Text(
                      "Additional Photos (Optional)",
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
                        physics: const BouncingScrollPhysics(),
                        itemCount: _additionalImageFiles.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // Plus button card
                            return GestureDetector(
                              onTap: _pickAdditionalImages,
                              child: Container(
                                width: 80.w,
                                margin: EdgeInsets.only(right: 10.w),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.02),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    style: BorderStyle.solid,
                                    width: 1.w,
                                  ),
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  color: AppColors.primaryPink,
                                  size: 24.sp,
                                ),
                              ),
                            );
                          }

                          final file = _additionalImageFiles[index - 1];
                          return Stack(
                            children: [
                              Container(
                                width: 80.w,
                                height: 80.h,
                                margin: EdgeInsets.only(right: 10.w),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    width: 1.w,
                                  ),
                                  image: DecorationImage(
                                    image: ResizeImage(FileImage(file),
                                        width: 100, height: 100),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4.h,
                                right: 14.w,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _additionalImageFiles.removeAt(index - 1);
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(3.w),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 10.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
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

                  // Options Switches
                  _buildSwitchOption(
                    title: "Mark as Milestone",
                    subtitle: "Highlighted with a gold border in your feed",
                    value: _isMilestone,
                    onChanged: (val) {
                      setState(() {
                        _isMilestone = val;
                      });
                    },
                  ),
                  UIHelper.verticalSpace(16.h),

                  // Layout selector
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
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
                      ),
                      SizedBox(width: 12.w),
                      Row(
                        children: [
                          _buildLayoutButton("full", Icons.splitscreen_rounded),
                          SizedBox(width: 8.w),
                          _buildLayoutButton("grid", Icons.grid_view_rounded),
                        ],
                      ),
                    ],
                  ),
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
                    if (_selectedImageFile == null) {
                      AppToast.show(
                        context,
                        title: "Required",
                        message: "Please select an image for this memory",
                        type: ToastType.error,
                      );
                      return;
                    }
                    widget.onAdd(
                      title: _titleController.text.trim(),
                      note: _noteController.text.trim(),
                      imageFile: _selectedImageFile,
                      additionalImageFiles: _additionalImageFiles,
                      isMilestone: _isMilestone,
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
      ),
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
          cursorColor: AppColors.primaryPink,
          style: GoogleFonts.dmSans(color: Colors.white, fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.03),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide:
                  BorderSide(color: Colors.white.withValues(alpha: 0.05)),
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
    required ValueChanged<bool>? onChanged,
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

  Widget _buildLayoutButton(String style, IconData icon) {
    final isSelected = _layoutType == style;
    return GestureDetector(
      onTap: () {
        setState(() {
          _layoutType = style;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPink.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPink
                : Colors.white.withValues(alpha: 0.05),
            width: 1.w,
          ),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primaryPink : Colors.white54,
          size: 20.sp,
        ),
      ),
    );
  }
}
