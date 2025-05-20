import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/themes/assets.dart';
import '../../core/themes/colors.dart';

class ContactInfo extends StatelessWidget {
  final String imgPath;
  final String title;
  const ContactInfo({super.key, required this.title, required this.imgPath});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(radius: 20, backgroundImage: AssetImage(imgPath)),
        Gap(10),
        Text(title, style: TextStyle(color: AppColors.glitch200)),
      ],
    );
  }
}
