import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class MessageReadStatus extends StatelessWidget {
  const MessageReadStatus({
    super.key,
    this.lastSentMessageStatus = MessageStatus.sent,
    required this.unreadCount,
  });

  final MessageStatus lastSentMessageStatus;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    if (unreadCount <= 0) {
      return WnImage(
        lastSentMessageStatus.imagePath,
        width: 17.5.w,
        height: 17.5.w,
        color: lastSentMessageStatus.color(context),
      );
    }
    return Container(
      padding:
          unreadCount > 99
              ? EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h)
              : EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: context.colors.primary,
        borderRadius: unreadCount > 99 ? BorderRadius.circular(12.r) : null,
        shape: unreadCount > 99 ? BoxShape.rectangle : BoxShape.circle,
      ),
      child: Text(
        unreadCount > 99 ? '99+' : unreadCount.toString(),
        style: TextStyle(
          fontSize: 12.sp,
          color: context.colors.primaryForeground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
