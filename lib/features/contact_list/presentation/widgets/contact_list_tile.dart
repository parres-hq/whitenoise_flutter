import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/core/utils/app_colors.dart';
import 'package:whitenoise/core/utils/assets_paths.dart';
import 'package:whitenoise/features/contact_list/models/chat_model.dart';

class ContactListTile extends StatelessWidget {
  final ChatModel contact;

  const ContactListTile({required this.contact, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30.r),
            child:
                contact.imagePath.isNotEmpty
                    ? Image.asset(contact.imagePath, width: 56.w, height: 56.w)
                    : Container(
                      width: 56.w,
                      height: 56.w,
                      color: Colors.orange,
                      alignment: Alignment.center,
                      child: Text(
                        contact.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(color: AppColors.white, fontSize: 20.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
          ),
          Gap(12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(contact.name, style: TextStyle(color: AppColors.color2D312D, fontSize: 18.sp, fontWeight: FontWeight.w500)),
                    Gap(6.w),
                    SvgPicture.asset(AssetsPaths.icVerifiedUser, height: 12.w, width: 12.w),
                  ],
                ),
                Text(
                  'npubt klkk3 vrzme 455yh 9rl2j shq7r c8dpe gj3hd f82c3 ks2sk 7qulx 40dxt 3vt',
                  style: TextStyle(color: AppColors.color727772, fontSize: 14.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
