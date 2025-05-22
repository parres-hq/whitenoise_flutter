import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class StackedReactions extends StatelessWidget {
  const StackedReactions({
    super.key,
    required this.reactions,
    this.size = 10.0,
    this.direction = TextDirection.ltr,
    this.maxVisible = 5,
    this.onReact,
    this.width,
  });

  final List<Reaction> reactions;
  final double size;
  final TextDirection direction;
  final int maxVisible;
  final VoidCallback? onReact;
  final double? width;

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

    return SizedBox(
      width: width,
      height: 24.h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: direction,
        children: [
          ...reactionsToShow.map((entry) {
            final emoji = entry.key;
            final count = entry.value;
            final isSingle = count == 1;

            return Padding(
              padding: EdgeInsets.only(right: 2.w),
              child: GestureDetector(
                onTap: onReact,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isSingle ? 0 : 4.w),
                  height: 20.h,
                  constraints: BoxConstraints(minWidth: 20.w),
                  decoration: BoxDecoration(
                    color: AppColors.colorE2E2E2,
                    border: Border.all(color: AppColors.white, width: 1.w),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: Text(
                      isSingle ? emoji : '$emoji$count',
                      style: TextStyle(fontSize: size.sp, color: AppColors.color727772),
                    ),
                  ),
                ),
              ),
            );
          }),

          // Show remaining count if needed
          if (remaining > 0)
            GestureDetector(
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
        ],
      ),
    );
  }
}
