import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/providers/avatar_color_provider.dart';
import 'package:whitenoise/domain/models/avatar_color_tokens.dart';
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
    this.colorToken,
  });
  final String imageUrl;
  final double size;
  final bool showBorder;
  final String? displayName;
  final String? pubkey;
  final AvatarColorToken? colorToken;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AvatarColorToken? token;
    if (colorToken != null) {
      token = colorToken;
    } else {
      final cacheKey =
          pubkey != null && pubkey!.isNotEmpty ? AvatarColorService.toCacheKey(pubkey!) : null;
      token = cacheKey != null ? ref.watch(avatarColorProvider)[cacheKey] : null;

      if (token == null && pubkey != null && pubkey!.isNotEmpty) {
        Future.microtask(() => ref.read(avatarColorProvider.notifier).getColorToken(pubkey!));
      }
    }

    final brightness = Theme.of(context).brightness;
    final backgroundColor = token?.getSurfaceColor(brightness) ?? context.colors.avatarSurface;
    final borderColor = token?.getBorderColor(brightness) ?? context.colors.border;
    final foregroundColor = token?.getForegroundColor(brightness) ?? context.colors.primary;

    return Container(
      width: size,
      height: size,
      decoration:
          showBorder && imageUrl.isEmpty
              ? BoxDecoration(
                border: Border.all(
                  color: borderColor,
                  width: 1.w,
                ),
                shape: BoxShape.circle,
              )
              : null,
      child: ClipOval(
        child: Container(
          color: backgroundColor,
          child: WnImage(
            imageUrl,
            size: size,
            fit: BoxFit.cover,
            fallbackWidget:
                (context) => FallbackAvatar(
                  displayName: displayName,
                  size: size,
                  textColor: foregroundColor,
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
