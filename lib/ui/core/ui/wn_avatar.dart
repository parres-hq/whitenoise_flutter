import 'dart:io';
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
      ),
      child: ClipOval(
        child: _buildChild(context),
      ),
    );
  }

  Widget _buildChild(BuildContext context) {
    // First priority: image if URL is not empty (network, local file, or asset)
    if (imageUrl.isNotEmpty) {
      // Try network image first
      if (imageUrl.startsWith('http')) {
        return Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(context),
        );
      }
      // Try local file image
      if (File(imageUrl).existsSync()) {
        return Image.file(
          File(imageUrl),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(context),
        );
      }
      // Try asset image
      return Image.asset(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        color: context.colors.primary,
        errorBuilder: (context, error, stackTrace) => _buildFallbackAvatar(context),
      );
    }
    // Second priority: fallback to displayName first letter or default avatar
    return _buildFallbackAvatar(context);
  }

  Widget _buildFallbackAvatar(BuildContext context) {
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
          color: 
            context.colors.primary,
           
        ),
      ),
    );
  }
}
