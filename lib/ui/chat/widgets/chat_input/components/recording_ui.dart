import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class RecordingUI extends StatelessWidget {
  const RecordingUI({
    super.key,
    required this.recordingTime,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragStart,
    required this.dragOffsetX,
    required this.isDragging,
  });

  final String recordingTime;
  final Function(DragUpdateDetails) onDragUpdate;
  final Function(DragEndDetails) onDragEnd;
  final Function(DragStartDetails) onDragStart;
  final double dragOffsetX;
  final bool isDragging;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(0.w, 16.w, 0.w, 16.w),
          child: Container(
            color: AppColors.glitch80,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                SizedBox(width: 8.w),
                Icon(CarbonIcons.microphone_filled, color: Colors.red, size: 18.w),
                SizedBox(width: 2.w),
                Text(
                  recordingTime,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.glitch900,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.only(right: 64.w),
                      child: Text(
                        "<   Slide to cancel   <",
                        style: TextStyle(fontSize: 12.sp, color: AppColors.glitch500),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          right: 0.w,
          top: 0.h,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: onDragStart,
            onHorizontalDragUpdate: onDragUpdate,
            onHorizontalDragEnd: onDragEnd,
            child: AnimatedContainer(
              duration: Duration(milliseconds: isDragging ? 0 : 100),
              transform: Matrix4.translationValues(dragOffsetX, 0, 0),
              curve: Curves.easeOut,
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Icon(CarbonIcons.microphone_filled, color: Colors.white, size: 20.w),
            ),
          ),
        ),
      ],
    );
  }
}
