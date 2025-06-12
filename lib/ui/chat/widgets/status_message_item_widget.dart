import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/themes/colors.dart';

class StatusMessageItemWidget extends StatelessWidget {
  final IconData icon;
  final String content;
  final String? boldText;

  const StatusMessageItemWidget({
    super.key,
    required this.icon,
    required this.content,
    this.boldText,
  });

  @override
  Widget build(BuildContext context) {
    final textParts = content.split(boldText ?? '');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.glitch600, size: 14),
        const Gap(5),
        Text.rich(
          textAlign: TextAlign.center,
          TextSpan(
            children: [
              if (textParts.length > 1) TextSpan(text: textParts[0]),
              if (boldText != null)
                TextSpan(
                  text: boldText,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              TextSpan(text: textParts.length > 1 ? textParts[1] : content),
            ],
            style: const TextStyle(color: AppColors.glitch600),
          ),
        ),
      ],
    );
  }
}
