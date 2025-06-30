import 'package:flutter/material.dart';
import 'package:whitenoise/ui/chat/widgets/chat_header_widget.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';

class ContactAvatar extends StatelessWidget {
  const ContactAvatar({
    super.key,
    required this.imgPath,
    this.size = 20,
    this.backgroundColor,
    this.borderColor,
    this.showBorder = false,
  });
  final String imgPath;
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? context.colors.avatarSurface,
        border:
            showBorder
                ? Border.all(
                  color: borderColor ?? context.colors.border,
                  width: 1.w,
                )
                : null,
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(imgPath.orDefault),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
