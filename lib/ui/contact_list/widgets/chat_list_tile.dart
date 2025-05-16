import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';
import 'package:whitenoise/domain/models/chat_model.dart';

class ChatListTile extends StatelessWidget {
  final ChatModel chat;

  const ChatListTile({required this.chat, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30.r),
            child:
                chat.imagePath.isNotEmpty
                    ? Image.asset(
                      chat.imagePath,
                      width: 56.w,
                      height: 56.w,
                      fit: BoxFit.cover,
                    )
                    : Container(
                      width: 56.w,
                      height: 56.w,
                      color: Colors.orange,
                      alignment: Alignment.center,
                      child: Text(
                        chat.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      chat.name,
                      style: TextStyle(
                        color: AppColors.color2D312D,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      chat.time,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.color727772,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.lastMessage,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.color727772,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (chat.unreadCount > 0)
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: const BoxDecoration(
                          color: AppColors.color202320,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          chat.unreadCount.toString(),
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    if (chat.hasAttachment)
                      SvgPicture.asset(
                        AssetsPaths.icDelivered,
                        width: 19.sp,
                        height: 13.sp,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
