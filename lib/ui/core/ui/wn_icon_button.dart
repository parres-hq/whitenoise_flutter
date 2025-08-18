import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class WnIconButton extends StatelessWidget {
  const WnIconButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.size = 52,
    this.iconSize = 20,
    this.backgroundColor,
    this.borderColor,
    this.iconColor,
    this.hasBorder = false,
  });
  final VoidCallback? onPressed;
  final IconData icon;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? iconColor;
  final bool hasBorder;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? context.colors.avatarSurface,
          border:
              hasBorder
                  ? Border.all(
                    color: borderColor ?? context.colors.input,
                  )
                  : null,
        ),
        child: Icon(
          icon,
          size: iconSize.sp,
          color: iconColor ?? context.colors.primary,
        ),
      ),
    );
  }
}
