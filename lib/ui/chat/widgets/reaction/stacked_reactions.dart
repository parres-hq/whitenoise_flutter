import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class StackedReactions extends StatelessWidget {
  const StackedReactions({
    super.key,
    required this.reactions,
    this.size = 11.0,
    this.stackedValue = 4.0,
    this.direction = TextDirection.ltr,
    this.maxVisible = 5,
    this.onReact,
  });

  // List of Reaction objects
  final List<Reaction> reactions;
  final double size;
  final double stackedValue;
  final TextDirection direction;
  final int maxVisible;
  final VoidCallback? onReact;

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Count emoji occurrences
    final emojiCounts = <String, int>{};
    for (final reaction in reactions) {
      emojiCounts[reaction.emoji] = (emojiCounts[reaction.emoji] ?? 0) + 1;
    }

    // Convert to list of emoji with counts
    final emojiEntries = emojiCounts.entries.toList();

    // Determine which reactions to show and how many are remaining
    final reactionsToShow = emojiEntries.length > maxVisible ? emojiEntries.sublist(0, maxVisible) : emojiEntries;
    final remaining = emojiEntries.length - reactionsToShow.length;

    // Build reaction widgets with proper stacking
    final reactionWidgets = <Widget>[];
    for (int i = 0; i < reactionsToShow.length; i++) {
      final entry = reactionsToShow[i];
      final emoji = entry.key;
      final count = entry.value;
      final isSingle = count == 1;

      final widget = GestureDetector(
        onTap: onReact,
        child: Container(
          width: isSingle ? 20.w : null,
          height: 20.h,
          padding: EdgeInsets.symmetric(horizontal: isSingle ? 0 : 4.w),
          decoration: BoxDecoration(
            color: AppColors.colorE2E2E2,
            border: Border.all(color: AppColors.white, width: 1.w),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Center(child: Text(isSingle ? emoji : '$emoji$count', style: TextStyle(fontSize: size.sp))),
        ),
      );

      // Apply stacking offset based on direction
      final offset = direction == TextDirection.ltr ? -i * stackedValue.w : i * stackedValue.w;

      reactionWidgets.add(
        Positioned(
          left: direction == TextDirection.ltr ? offset : null,
          right: direction == TextDirection.rtl ? offset : null,
          child: widget,
        ),
      );
    }

    return Container(
      height: 20.h,
      margin: EdgeInsets.only(top: 4.h),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Stacked reaction widgets
          ...reactionWidgets,

          // Remaining counter if needed
          if (remaining > 0)
            Positioned(
              left: direction == TextDirection.ltr ? (maxVisible * stackedValue).w : null,
              right: direction == TextDirection.rtl ? (maxVisible * stackedValue).w : null,
              child: GestureDetector(
                onTap: onReact,
                child: Container(
                  width: 24.w,
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: AppColors.colorE2E2E2,
                    border: Border.all(color: AppColors.white, width: 1.w),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: Text('+$remaining', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
