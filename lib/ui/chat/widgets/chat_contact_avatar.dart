import 'package:flutter/material.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';

class ChatContactAvatar extends StatelessWidget {
  const ChatContactAvatar({
    super.key,
    required this.imgPath,
    this.size = 20,
    this.backgroundColor,
    this.borderColor,
  });

  final String imgPath;
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colors.avatarSurface,
        border: Border.all(
          color: borderColor ?? context.colors.border,
          width: 1.w,
        ),
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(imgPath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
