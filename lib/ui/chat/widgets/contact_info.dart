import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';

class ContactInfo extends StatelessWidget {
  final String imgPath;
  final String title;
  const ContactInfo({super.key, required this.title, required this.imgPath});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 18.w, backgroundImage: AssetImage(imgPath)),
        Gap(6.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.appBarForeground,
          ),
        ),
      ],
    );
  }
}
