import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';


class ReplyEditHeader extends StatelessWidget {
  const ReplyEditHeader({
    super.key,
    this.replyingTo,
    this.editingMessage,
    required this.onCancel,
  });

  final MessageModel? replyingTo;
  final MessageModel? editingMessage;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.glitch100,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.r)),
      ),
      child: Row(
        children: [
          Icon(
            replyingTo != null ? CarbonIcons.reply : CarbonIcons.edit,
            size: 16.w,
            color: AppColors.glitch500,
          ),
          SizedBox(width: 8.w),
          Gap(6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  replyingTo != null ? "Replying to ${replyingTo!.sender.name}" : "Editing message",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.glitch700,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (replyingTo?.type == MessageType.text && replyingTo?.content != null)
                  Text(
                    replyingTo?.content ?? '',
                    style: TextStyle(fontSize: 12.sp, color: AppColors.glitch700),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Icon(CarbonIcons.close, size: 16.w, color: AppColors.glitch500),
          ),
        ],
      ),
    );
  }
}
