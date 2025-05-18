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

  const ContactListTile({
    required this.contact,
    this.onTap,
    this.isSelected = false,
    this.showCheck = false,
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
                      Text(
                        contact.name,
                        style: TextStyle(color: AppColors.color2D312D, fontSize: 18.sp, fontWeight: FontWeight.w500),
                      ),
                      Gap(6.w),
                      SvgPicture.asset(AssetsPaths.icVerifiedUser, height: 12.w, width: 12.w),
                    ],
                  ),
                  Text(
                    contact.publicKey,
                    style: TextStyle(color: AppColors.color727772, fontSize: 14.sp),
                  ),
                ],
              ),
            ),
            if (showCheck)
              Container(
                width: 18.w,
                height: 18.w,
                decoration: BoxDecoration(
                  border: Border.all(color: isSelected ? AppColors.color202320 : AppColors.colorE2E2E2, width: 1.5.w),
                  color: isSelected ? AppColors.color202320 : Colors.transparent,
                ),
                child: isSelected ? Icon(Icons.check, size: 12.w, color: Colors.white) : null,
              ),
          ],
        ),
      ),
    );
  }
}
