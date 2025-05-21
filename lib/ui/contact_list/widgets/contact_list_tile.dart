import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/models/contact_model.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class ContactListTile extends StatelessWidget {
  final ContactModel contact;
  final bool isSelected;
  final VoidCallback? onTap;
  final bool showCheck;
  final bool showExpansionArrow;

  const ContactListTile({
    required this.contact,
    this.onTap,
    this.isSelected = false,
    this.showCheck = false,
    this.showExpansionArrow = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(30.r),
              child:
                  contact.imagePath.isNotEmpty
                      ? Image.asset(
                        contact.imagePath,
                        width: 56.w,
                        height: 56.w,
                      )
                      : Container(
                        width: 56.w,
                        height: 56.w,
                        color: Colors.orange,
                        alignment: Alignment.center,
                        child: Text(
                          contact.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 20.sp,
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
                    children: [
                      Text(
                        contact.name,
                        style: TextStyle(
                          color: AppColors.glitch900,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Gap(6.w),
                      SvgPicture.asset(
                        AssetsPaths.icVerifiedUser,
                        height: 12.w,
                        width: 12.w,
                      ),
                    ],
                  ),
                  Text(
                    contact.publicKey,
                    style: TextStyle(
                      color: AppColors.glitch600,
                      fontSize: showExpansionArrow ? 12.sp : 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            if (showCheck) ...[
              Gap(16.w),
              Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  border: Border.all(
                    color:
                        isSelected ? AppColors.glitch950 : AppColors.glitch200,
                    width: 1.5.w,
                  ),
                  color: isSelected ? AppColors.glitch950 : Colors.transparent,
                ),
                child:
                    isSelected
                        ? Icon(Icons.check, size: 12.w, color: Colors.white)
                        : null,
              ),
            ] else if (showExpansionArrow) ...[
              Gap(16.w),
              SvgPicture.asset(AssetsPaths.icExpand, width: 11.w, height: 18.w),
            ],
          ],
        ),
      ),
    );
  }
}
