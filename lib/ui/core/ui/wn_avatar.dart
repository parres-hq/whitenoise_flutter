import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/avatar_color_provider.dart';
import 'package:whitenoise/domain/services/avatar_color_service.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

class WnAvatar extends ConsumerWidget {
  const WnAvatar({
    super.key,
    required this.imageUrl,
    this.size = 20,
    this.showBorder = false,
    this.displayName,
    this.pubkey,
  });
  final String imageUrl;
  final double size;
  final bool showBorder;
  final String? displayName;
  final String? pubkey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cacheKey =
        pubkey != null && pubkey!.isNotEmpty ? AvatarColorService.toCacheKey(pubkey!) : null;
    final themeColor = cacheKey != null ? ref.watch(avatarColorProvider)[cacheKey] : null;

    // Use a single ClipOval with decoration instead of Container + ClipOval
    return Container(
      width: size,
      height: size,
      decoration:
          showBorder
              ? BoxDecoration(
                border: Border.all(
                  color: themeColor?.withValues(alpha: 0.5) ?? context.colors.border,
                  width: 1.w,
                ),
                shape: BoxShape.circle,
              )
              : null,
      child: ClipOval(
        child: Container(
          width: size,
          height: size,
          color: themeColor?.withValues(alpha: 0.2) ?? context.colors.avatarSurface,
          child: WnImage(
            imageUrl,
            size: size,
            fit: BoxFit.cover,
            fallbackWidget:
                (context) => FallbackAvatar(
                  displayName: displayName,
                  size: size,
                  textColor: themeColor ?? context.colors.primary,
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
    this.textColor,
  });

  final String? displayName;
  final double size;
  final Color? textColor;

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
            color: textColor,
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
          color: textColor,
        ),
      ),
    );
  }
}
