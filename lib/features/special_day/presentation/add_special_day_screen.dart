import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:bea_window_app/gen/colors.gen.dart';
import 'package:bea_window_app/helpers/ui_helpers.dart';
import '../models/special_day_model.dart';
import 'package:bea_window_app/common_widgets/app_toast.dart';

class AddSpecialDayScreen extends StatefulWidget {
  final SpecialDayModel? existingDay;
  final Function(String title, String description, DateTime date) onSave;

  const AddSpecialDayScreen({
    super.key,
    this.existingDay,
    required this.onSave,
  });

  @override
  State<AddSpecialDayScreen> createState() => _AddSpecialDayScreenState();
}

class _AddSpecialDayScreenState extends State<AddSpecialDayScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingDay?.title ?? '');
    _descriptionController = TextEditingController(text: widget.existingDay?.description ?? '');
    _selectedDate = widget.existingDay?.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 50);
    final lastDate = DateTime(now.year + 50);

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryPink,
              onPrimary: Colors.white,
              surface: AppColors.navBgColor,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.navBgColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      AppToast.show(
        context,
        title: "Required Field",
        message: "Please select a date!",
        type: ToastType.error,
      );
      return;
    }

    widget.onSave(
      _titleController.text.trim(),
      _descriptionController.text.trim(),
      _selectedDate!,
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingDay != null;

    return Scaffold(
      backgroundColor: AppColors.softBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? "Edit Special Day" : "Add Special Day",
          style: GoogleFonts.dmSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Special Day Title",
                    style: GoogleFonts.dmSans(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  UIHelper.verticalSpace(8.h),
                  TextFormField(
                    controller: _titleController,
                    style: GoogleFonts.dmSans(color: Colors.white),
                    cursorColor: AppColors.primaryPink,
                    decoration: InputDecoration(
                      hintText: "Anniversary, First Meet, Birthday...",
                      hintStyle: GoogleFonts.dmSans(color: Colors.white24, fontSize: 13.sp),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: const BorderSide(color: AppColors.primaryPink),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return "Title cannot be empty";
                      }
                      return null;
                    },
                  ),
                  UIHelper.verticalSpace(20.h),
                  Text(
                    "Why This Is Special",
                    style: GoogleFonts.dmSans(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  UIHelper.verticalSpace(8.h),
                  TextFormField(
                    controller: _descriptionController,
                    style: GoogleFonts.dmSans(color: Colors.white),
                    cursorColor: AppColors.primaryPink,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "This was the day we first met and started our journey together...",
                      hintStyle: GoogleFonts.dmSans(color: Colors.white24, fontSize: 13.sp),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.03),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.r),
                        borderSide: const BorderSide(color: AppColors.primaryPink),
                      ),
                    ),
                  ),
                  UIHelper.verticalSpace(20.h),
                  Text(
                    "Select Date",
                    style: GoogleFonts.dmSans(
                      color: Colors.white70,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  UIHelper.verticalSpace(8.h),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDate == null
                                ? "Select Date"
                                : DateFormat('MMMM d, yyyy').format(_selectedDate!),
                            style: GoogleFonts.dmSans(
                              color: _selectedDate == null ? Colors.white24 : Colors.white,
                              fontSize: 13.sp,
                            ),
                          ),
                          const Icon(Icons.calendar_today_rounded, color: AppColors.primaryPink),
                        ],
                      ),
                    ),
                  ),
                  UIHelper.verticalSpace(40.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      onPressed: _submit,
                      child: Text(
                        isEdit ? "Update Special Day" : "Save Special Day",
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
