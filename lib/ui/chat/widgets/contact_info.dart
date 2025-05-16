import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/themes/assets.dart';
import '../../core/themes/colors.dart';

class ContactInfo extends StatelessWidget {
  const ContactInfo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundImage: AssetImage(AssetsPaths.icImage),
        ),
        Gap(10),
        Text('Marek', style: TextStyle(color: AppColors.colorE2E2E2,),),
      ],
    );
  }
}