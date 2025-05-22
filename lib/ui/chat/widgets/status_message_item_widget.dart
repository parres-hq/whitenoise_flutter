import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/themes/colors.dart';

class StatusMessageItemWidget extends StatelessWidget {
  final IconData icon;
  final String highlightedContent;
  final String content;
  const StatusMessageItemWidget({
    super.key,
    required this.icon,
    required this.highlightedContent,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.glitch600, size: 14),
        Gap(5),
        Text.rich(
          textAlign: TextAlign.center,
          TextSpan(
            text: highlightedContent,
            style: TextStyle(color: AppColors.glitch950),
            children: <TextSpan>[
              TextSpan(
                text: content,
                style: TextStyle(color: AppColors.glitch600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
