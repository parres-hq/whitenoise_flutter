import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
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
        const Gap(10),
        Text(title, style: const TextStyle(color: AppColors.glitch50)),
      ],
    );
  }
}
