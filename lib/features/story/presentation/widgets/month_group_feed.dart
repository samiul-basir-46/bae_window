import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/story_state.dart';
import 'memory_card.dart';

class MonthGroupFeed extends StatelessWidget {
  final String month;
  final List<MemoryItem> items;
  final Function(MemoryItem) onCardLongPress;

  const MonthGroupFeed({
    super.key,
    required this.month,
    required this.items,
    required this.onCardLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final listItems = <Widget>[];

    int i = 0;
    while (i < items.length) {
      final item = items[i];
      if (item.layoutType == "full") {
        listItems.add(
          FullWidthMemoryCard(
            memory: item,
            onLongPress: () => onCardLongPress(item),
          ),
        );
        i++;
      } else {
        // Grid item: see if there is another grid item next
        if (i + 1 < items.length && items[i + 1].layoutType == "grid") {
          final nextItem = items[i + 1];
          listItems.add(
            Row(
              children: [
                Expanded(
                  child: GridMemoryCard(
                    memory: item,
                    onLongPress: () => onCardLongPress(item),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: GridMemoryCard(
                    memory: nextItem,
                    onLongPress: () => onCardLongPress(nextItem),
                  ),
                ),
              ],
            ),
          );
          i += 2;
        } else {
          // Odd grid item, render as single grid item
          listItems.add(
            Row(
              children: [
                Expanded(
                  child: GridMemoryCard(
                    memory: item,
                    onLongPress: () => onCardLongPress(item),
                  ),
                ),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          );
          i++;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 16.h, bottom: 12.h, left: 4.w),
          child: Text(
            month,
            style: GoogleFonts.dmSans(
              color: Colors.white38,
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...listItems.map((widget) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: widget,
            )),
      ],
    );
  }
}
