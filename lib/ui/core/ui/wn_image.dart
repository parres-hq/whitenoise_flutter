import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A reusable image widget that automatically chooses the best
/// underlying widget based on the provided [src].
///
/// - Network (http/https):
///   - .svg -> SvgPicture.network
///   - others -> CachedNetworkImage
/// - Local file:
///   - .svg -> SvgPicture.file
///   - others -> Image.file
/// - Asset:
///   - .svg -> SvgPicture.asset
///   - others -> Image.asset
class WnImage extends StatelessWidget {
  const WnImage(
    this.src, {
    super.key,
    this.width,
    this.height,
    this.size,
    this.fit,
    this.alignment = Alignment.center,
    this.color,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.fallbackWidget,
    this.clipBehavior = Clip.hardEdge,
    this.cacheKey,
    this.semanticLabel,
  });

  /// Image source (path, link).
  final String src;

  /// The width of the image. Use ```size``` if you wish to set a square image.
  /// i.e. width == height.
  final double? width;

  /// The height of the image. Use ```size``` if you wish to set a square image.
  /// i.e. width == height.
  final double? height;

  /// This is used for square images (used as both height and width).
  final double? size;
  final BoxFit? fit;
  final Alignment alignment;
  final Color? color;
  final BorderRadius? borderRadius;
  final WidgetBuilder? placeholder;
  final WidgetBuilder? errorWidget;
  final WidgetBuilder? fallbackWidget;
  final Clip clipBehavior;
  final String? cacheKey;
  final String? semanticLabel;

  bool get _isNetwork {
    final uri = Uri.tryParse(src);
    return uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }

  bool get _isLocalFile {
    return !_isNetwork && File(src).existsSync();
  }

  bool get _isSvg => src.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    // Guard against empty or null src
    if (src.isEmpty) {
      return _buildFallback(context);
    }

    final Widget child;

    if (_isNetwork) {
      if (_isSvg) {
        final color = this.color;
        child = SvgPicture.network(
          src,
          width: size ?? width,
          height: size ?? height,
          fit: fit ?? BoxFit.contain,
          alignment: alignment,
          colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
          semanticsLabel: semanticLabel,
          placeholderBuilder: (context) => _buildPlaceholder(context),
          errorBuilder: (context, error, stackTrace) => _buildFallback(context),
        );
      } else {
        final width = size ?? this.width;
        final height = size ?? this.height;
        child = CachedNetworkImage(
          imageUrl: src,
          width: width,
          height: height,
          fit: fit,
          alignment: alignment,
          memCacheWidth:
              width == null ? null : (width * MediaQuery.devicePixelRatioOf(context)).round(),
          memCacheHeight:
              height == null ? null : (height * MediaQuery.devicePixelRatioOf(context)).round(),
          cacheKey: cacheKey,
          placeholder: (context, url) => _buildPlaceholder(context),
          errorWidget: (context, url, error) => _buildFallback(context),
          color: color,
          colorBlendMode: color == null ? null : BlendMode.srcIn,
          imageBuilder:
              (context, provider) => Image(
                image: provider,
                width: width,
                height: height,
                fit: fit,
                alignment: alignment,
                color: color,
                colorBlendMode: color == null ? null : BlendMode.srcIn,
                semanticLabel: semanticLabel,
                errorBuilder: (context, error, stackTrace) => _buildFallback(context),
              ),
        );
      }
    } else if (_isLocalFile) {
      if (_isSvg) {
        final color = this.color;
        child = SvgPicture.file(
          File(src),
          width: size ?? width,
          height: size ?? height,
          fit: fit ?? BoxFit.contain,
          alignment: alignment,
          colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
          semanticsLabel: semanticLabel,
          placeholderBuilder: (context) => _buildPlaceholder(context),
          errorBuilder: (context, error, stackTrace) => _buildFallback(context),
        );
      } else {
        child = Image.file(
          File(src),
          width: size ?? width,
          height: size ?? height,
          fit: fit,
          alignment: alignment,
          color: color,
          colorBlendMode: color == null ? null : BlendMode.srcIn,
          semanticLabel: semanticLabel,
          errorBuilder: (context, error, stackTrace) => _buildFallback(context),
        );
      }
    } else {
      // Try as asset
      if (_isSvg) {
        final color = this.color;
        child = SvgPicture.asset(
          src,
          width: size ?? width,
          height: size ?? height,
          fit: fit ?? BoxFit.contain,
          alignment: alignment,
          colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
          semanticsLabel: semanticLabel,
          errorBuilder: (context, error, stackTrace) => _buildFallback(context),
        );
      } else {
        child = Image.asset(
          src,
          width: size ?? width,
          height: size ?? height,
          fit: fit,
          alignment: alignment,
          color: color,
          colorBlendMode: color == null ? null : BlendMode.srcIn,
          semanticLabel: semanticLabel,
          errorBuilder: (context, error, stackTrace) => _buildFallback(context),
        );
      }
    }
    final borderRadius = this.borderRadius;
    if (borderRadius == null) return child;

    return ClipRRect(
      clipBehavior: clipBehavior,
      borderRadius: borderRadius,
      child: child,
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final placeholder = this.placeholder;
    if (placeholder != null) return placeholder(context);
    return SizedBox(
      width: size ?? width,
      height: size ?? height,
      child: const Center(child: CircularProgressIndicator.adaptive(strokeWidth: 1.8)),
    );
  }

  Widget _buildError(BuildContext context) {
    final errorWidget = this.errorWidget;
    if (errorWidget != null) return errorWidget(context);
    final width = size ?? this.width;
    final height = size ?? this.height;
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: (width != null && height != null) ? (0.5 * (width + height) / 2) : 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    // First try the custom fallback widget
    final fallbackWidget = this.fallbackWidget;
    if (fallbackWidget != null) return fallbackWidget(context);

    // Then try the error widget
    final errorWidget = this.errorWidget;
    if (errorWidget != null) return errorWidget(context);

    // Finally use the default error display
    return _buildError(context);
  }
}
