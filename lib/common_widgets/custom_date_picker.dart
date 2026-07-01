import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const CustomDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) {
    return showDialog<DateTime>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 20.w),
        child: CustomDatePicker(
          initialDate: initialDate,
          firstDate: firstDate,
          lastDate: lastDate,
        ),
      ),
    );
  }

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;
  bool _showYearSelection = false;

  final List<String> _weekDays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(widget.initialDate.year, widget.initialDate.month);
    _selectedDate = widget.initialDate;
  }

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  List<DateTime> _generateDaysInMonth(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final dayOfWeek = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    final startOffset = dayOfWeek - 1; // Days of prev month to display

    final totalDays = DateTime(month.year, month.month + 1, 0).day;
    final List<DateTime> days = [];

    // Add padding days from prev month
    final prevMonthEnd = DateTime(month.year, month.month, 0).day;
    for (int i = startOffset - 1; i >= 0; i--) {
      days.add(DateTime(month.year, month.month - 1, prevMonthEnd - i));
    }

    // Add days of current month
    for (int i = 1; i <= totalDays; i++) {
      days.add(DateTime(month.year, month.month, i));
    }

    // Add padding days from next month to make grid complete (multiple of 7)
    final remaining = 42 - days.length;
    for (int i = 1; i <= remaining; i++) {
      days.add(DateTime(month.year, month.month + 1, i));
    }

    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _generateDaysInMonth(_focusedMonth);
    final years = List<int>.generate(
      widget.lastDate.year - widget.firstDate.year + 1,
      (index) => widget.firstDate.year + index,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBgColor,
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 24.r,
            spreadRadius: 4.r,
          ),
        ],
      ),
      padding: EdgeInsets.all(24.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Month / Year Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  _showYearSelection ? Icons.arrow_back_rounded : Icons.chevron_left_rounded,
                  color: Colors.white70,
                  size: 24.sp,
                ),
                onPressed: _showYearSelection
                    ? () => setState(() => _showYearSelection = false)
                    : _prevMonth,
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showYearSelection = !_showYearSelection;
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: _showYearSelection ? AppColors.primaryPink.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _showYearSelection
                            ? "Select Year"
                            : "${_months[_focusedMonth.month - 1]} ${_focusedMonth.year}",
                        style: GoogleFonts.dmSans(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Icon(
                        _showYearSelection ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                        color: Colors.white70,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded, color: _showYearSelection ? Colors.transparent : Colors.white70, size: 24.sp),
                onPressed: _showYearSelection ? null : _nextMonth,
              ),
            ],
          ),
          SizedBox(height: 16.h),

          if (_showYearSelection) ...[
            // Year Grid Selector
            SizedBox(
              height: 240.h,
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: years.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10.h,
                  crossAxisSpacing: 10.w,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (context, index) {
                  final year = years[index];
                  final isCurrentFocusedYear = year == _focusedMonth.year;
                  final isSelectedYear = _selectedDate != null && year == _selectedDate!.year;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _focusedMonth = DateTime(year, _focusedMonth.month);
                        _showYearSelection = false;
                      });
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelectedYear
                            ? AppColors.primaryPink
                            : isCurrentFocusedYear
                                ? AppColors.primaryPink.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: isCurrentFocusedYear && !isSelectedYear
                              ? AppColors.primaryPink.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.05),
                          width: 1.w,
                        ),
                      ),
                      child: Text(
                        "$year",
                        style: GoogleFonts.dmSans(
                          color: isSelectedYear || isCurrentFocusedYear ? Colors.white : Colors.white70,
                          fontSize: 13.sp,
                          fontWeight: isSelectedYear || isCurrentFocusedYear ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else ...[
            // Week Days Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _weekDays.map((day) {
                return SizedBox(
                  width: 32.w,
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      color: Colors.white30,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 8.h),

            // Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6.h,
                crossAxisSpacing: 6.w,
              ),
              itemBuilder: (context, index) {
                final date = days[index];
                final isCurrentMonth = date.month == _focusedMonth.month;
                final isSelected = _selectedDate != null &&
                    date.year == _selectedDate!.year &&
                    date.month == _selectedDate!.month &&
                    date.day == _selectedDate!.day;

                final isToday = DateTime.now().year == date.year &&
                    DateTime.now().month == date.month &&
                    DateTime.now().day == date.day;

                return GestureDetector(
                  onTap: () {
                    if (date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate)) return;
                    setState(() {
                      _selectedDate = date;
                    });
                  },
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.primaryPink
                          : isToday
                              ? AppColors.primaryPink.withValues(alpha: 0.15)
                              : Colors.transparent,
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.primaryPink.withValues(alpha: 0.5), width: 1.w)
                          : null,
                    ),
                    child: Text(
                      "${date.day}",
                      style: GoogleFonts.dmSans(
                        color: isSelected
                            ? Colors.white
                            : !isCurrentMonth
                                ? Colors.white10
                                : (date.isBefore(widget.firstDate) || date.isAfter(widget.lastDate))
                                    ? Colors.white24
                                    : Colors.white70,
                        fontSize: 12.sp,
                        fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
          SizedBox(height: 24.h),

          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.dmSans(
                    color: Colors.white54,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: () => Navigator.pop(context, _selectedDate),
                child: Text(
                  "Select",
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
