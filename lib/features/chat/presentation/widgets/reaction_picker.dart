import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bea_window_app/gen/colors.gen.dart';

class ReactionPicker extends StatelessWidget {
  final Function(String emoji) onReactionSelected;
  final VoidCallback onDismiss;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
    required this.onDismiss,
  });

  static const List<String> _quickEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
  static const List<String> _expandedEmojis = [
    '🔥', '👏', '🎉', '💡', '✨', '👀', '💯', '🤔',
    '😍', '🤩', '😎', '😜', '😭', '😡', '😱', '💩',
    '🤝', '💖', '🌟', '🌈', '🍕', '🎉', '🎈', '🧸'
  ];

  void _showAllEmojisSheet(BuildContext context) {
    final navigator = Navigator.of(context);
    onDismiss(); // Dismiss floating picker first
    showModalBottomSheet(
      context: navigator.context,
      backgroundColor: AppColors.softBlack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'Reactions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  itemCount: _expandedEmojis.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, index) {
                    final emoji = _expandedEmojis[index];
                    return GestureDetector(
                      onTap: () {
                        onReactionSelected(emoji);
                        Navigator.pop(context);
                      },
                      child: Center(
                        child: Text(
                          emoji,
                          style: TextStyle(fontSize: 30.sp),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.navBgColor.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(30.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ..._quickEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () => onReactionSelected(emoji),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.w),
                    child: ScaleTransition(
                      scale: const AlwaysStoppedAnimation(1.0),
                      child: Text(
                        emoji,
                        style: TextStyle(fontSize: 24.sp),
                      ),
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () => _showAllEmojisSheet(context),
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  margin: EdgeInsets.only(left: 6.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 16.sp,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
