import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class MessageSenderInfo extends StatelessWidget {
  final MessageModel message;
  final bool isSameSenderAsNext;

  const MessageSenderInfo({
    super.key,
    required this.message,
    required this.isSameSenderAsNext,
  });

  @override
  Widget build(BuildContext context) {
    if (isSameSenderAsNext) return SizedBox(width: 38.w);

    return Padding(
      padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15.r),
        child: CachedNetworkImage(
          imageUrl: message.sender.imagePath ?? '',
          width: 30.w,
          height: 30.h,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 30.w,
            height: 30.h,
            color: AppColors.glitch950.withOpacity(0.1),
          ),
          errorWidget: (context, url, error) => Icon(
            CarbonIcons.user_avatar,
            size: 30.w,
            color: AppColors.glitch50,
          ),
        ),
      ),
    );
  }
}