import 'package:flutter/material.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class WnAvatar extends StatelessWidget {
  const WnAvatar({
    super.key,
    required this.imageUrl,
    this.size = 20,
    this.backgroundColor,
    this.borderColor,
    this.showBorder = false,
    this.displayName,
  });
  final String imageUrl;
  final double size;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showBorder;
  final String? displayName;

  @override
  Widget build(BuildContext context) {
    // Use a single ClipOval with decoration instead of Container + ClipOval
    return Container(
      width: size,
      height: size,
      decoration:
          showBorder
              ? BoxDecoration(
                border: Border.all(
                  color: borderColor ?? context.colors.border,
                  width: 1.w,
                ),
                shape: BoxShape.circle,
              )
              : null,
      child: ClipOval(
        child: Container(
          width: size,
          height: size,
          color: backgroundColor ?? context.colors.avatarSurface,
          child: WnImage(
            imageUrl,
            size: size,
            fit: BoxFit.cover,
            fallbackWidget:
                (context) => FallbackAvatar(
                  displayName: displayName,
                  size: size,
                ),
          ),
        ),
      ),
    );
  }
}

class FallbackAvatar extends StatelessWidget {
  const FallbackAvatar({
    super.key,
    required this.displayName,
    required this.size,
  });

  final String? displayName;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Show first letter of displayName if available
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return Center(
        child: Text(
          displayName!.trim().substring(0, 1).toUpperCase(),
          style: TextStyle(
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
            color: context.colors.primary,
          ),
        ),
      );
    }

    // Final fallback: Default avatar asset with proper padding
    return Padding(
      padding: EdgeInsets.all(size * 0.25),
      child: Center(
        child: WnImage(
          AssetsPaths.icUser,
          width: size * 0.4,
          height: size * 0.4,
          color: context.colors.primary,
        ),
      ),
    );
  }
}
