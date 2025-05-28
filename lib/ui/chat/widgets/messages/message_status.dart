import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class MessageStatusWidget extends StatelessWidget {
  final MessageModel message;

  const MessageStatusWidget({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final textColor = message.isMe ? AppColors.glitch50 : AppColors.glitch900;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.timeSent,
          style: TextStyle(
            fontSize: 10.sp,
            color: textColor.withOpacity(0.7),
            decoration: TextDecoration.none,
          ),
        ),
        Gap(4.w),
        if (message.isMe)
          Icon(
            _getStatusIcon(message.status),
            size: 12.w,
            color: _getStatusColor(message.status, context),
          ),
      ],
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return CarbonIcons.time;
      case MessageStatus.sent:
      case MessageStatus.delivered:
        return CarbonIcons.checkmark_outline;
      case MessageStatus.read:
        return CarbonIcons.checkmark_filled;
      case MessageStatus.failed:
        return CarbonIcons.warning;
    }
  }

  Color _getStatusColor(MessageStatus status, BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return AppColors.glitch50.withOpacity(0.5);
      case MessageStatus.sent:
        return AppColors.glitch50.withOpacity(0.7);
      case MessageStatus.delivered:
        return AppColors.glitch50;
      case MessageStatus.read:
        return AppColors.glitch100;
      case MessageStatus.failed:
        return Theme.of(context).colorScheme.error;
    }
  }
}
