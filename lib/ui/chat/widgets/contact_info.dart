import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/chat/widgets/chat_contact_avatar.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';

class ContactInfo extends StatelessWidget {
  final String imgPath;
  final String title;
  const ContactInfo({super.key, required this.title, required this.imgPath});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ChatContactAvatar(
          imgPath: imgPath,
          size: 36.r,
        ),
        Gap(8.w),
        Text(title),
      ],
    );
  }
}
