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
class WnImage extends StatefulWidget {
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

  @override
  State<WnImage> createState() => _WnImageState();
}

class _WnImageState extends State<WnImage> {
  // Cache expensive computations
  Uri? _parsedUri;
  bool? _isNetwork;
  bool? _isLocalFile;
  bool? _isSvg;
  double? _cachedDevicePixelRatio;

  @override
  void initState() {
    super.initState();
    _computeImageProperties();
  }

  @override
  void didUpdateWidget(WnImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) {
      _computeImageProperties();
    }
  }

  void _computeImageProperties() {
    _parsedUri = Uri.tryParse(widget.src);
    _isNetwork =
        _parsedUri != null &&
        _parsedUri!.hasScheme &&
        (_parsedUri!.scheme == 'http' || _parsedUri!.scheme == 'https');
    _isSvg = widget.src.toLowerCase().endsWith('.svg');

    // For local files, we'll check asynchronously to avoid blocking
    if (!_isNetwork!) {
      _checkLocalFileAsync();
    } else {
      _isLocalFile = false;
    }
  }

  void _checkLocalFileAsync() async {
    try {
      final file = File(widget.src);
      // ignore: avoid_slow_async_io
      final exists = await file.exists();
      if (mounted) {
        setState(() {
          _isLocalFile = exists;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocalFile = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Cache device pixel ratio
    _cachedDevicePixelRatio ??= MediaQuery.devicePixelRatioOf(context);

    // Guard against empty or null src
    if (widget.src.isEmpty) {
      return _buildFallback(context);
    }

    // If we're still checking local file existence, show placeholder
    if (_isLocalFile == null && !(_isNetwork ?? false)) {
      return _buildPlaceholder(context);
    }

    final Widget child;

    if (_isNetwork ?? false) {
      if (_isSvg ?? false) {
        final color = widget.color;
        child = SvgPicture.network(
          widget.src,
          width: widget.size ?? widget.width,
          height: widget.size ?? widget.height,
          fit: widget.fit ?? BoxFit.contain,
          alignment: widget.alignment,
          colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
          semanticsLabel: widget.semanticLabel,
          placeholderBuilder: (context) => _buildPlaceholder(context),
          errorBuilder: (context, error, stackTrace) => _buildFallback(context),
        );
      } else {
        final width = widget.size ?? widget.width;
        final height = widget.size ?? widget.height;
        child = CachedNetworkImage(
          imageUrl: widget.src,
          width: width,
          height: height,
          fit: widget.fit,
          alignment: widget.alignment,
          memCacheWidth: width == null ? null : (width * _cachedDevicePixelRatio!).round(),
          memCacheHeight: height == null ? null : (height * _cachedDevicePixelRatio!).round(),
          cacheKey: widget.cacheKey,
          placeholder: (context, url) => _buildPlaceholder(context),
          errorWidget: (context, url, error) => _buildFallback(context),
          color: widget.color,
          colorBlendMode: widget.color == null ? null : BlendMode.srcIn,
          imageBuilder:
              (context, provider) => Image(
                image: provider,
                width: width,
                height: height,
                fit: widget.fit,
                alignment: widget.alignment,
                color: widget.color,
                colorBlendMode: widget.color == null ? null : BlendMode.srcIn,
                semanticLabel: widget.semanticLabel,
                errorBuilder: (context, error, stackTrace) => _buildFallback(context),
              ),
        );
      }
    } else if (_isLocalFile ?? false) {
      if (_isSvg ?? false) {
        final color = widget.color;
        child = SvgPicture.file(
          File(widget.src),
          width: widget.size ?? widget.width,
          height: widget.size ?? widget.height,
          fit: widget.fit ?? BoxFit.contain,
          alignment: widget.alignment,
          colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
          semanticsLabel: widget.semanticLabel,
          placeholderBuilder: (context) => _buildPlaceholder(context),
          errorBuilder: (context, error, stackTrace) => _buildFallback(context),
        );
      } else {
        child = Image.file(
          File(widget.src),
          width: widget.size ?? widget.width,
          height: widget.size ?? widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          color: widget.color,
          colorBlendMode: widget.color == null ? null : BlendMode.srcIn,
          semanticLabel: widget.semanticLabel,
          errorBuilder: (context, error, stackTrace) => _buildFallback(context),
        );
      }
    } else {
      // Try as asset
      if (_isSvg ?? false) {
        final color = widget.color;
        child = SvgPicture.asset(
          widget.src,
          width: widget.size ?? widget.width,
          height: widget.size ?? widget.height,
          fit: widget.fit ?? BoxFit.contain,
          alignment: widget.alignment,
          colorFilter: color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
          semanticsLabel: widget.semanticLabel,
          errorBuilder: (context, error, stackTrace) => _buildFallback(context),
        );
      } else {
        child = Image.asset(
          widget.src,
          width: widget.size ?? widget.width,
          height: widget.size ?? widget.height,
          fit: widget.fit,
          alignment: widget.alignment,
          color: widget.color,
          colorBlendMode: widget.color == null ? null : BlendMode.srcIn,
          semanticLabel: widget.semanticLabel,
          errorBuilder: (context, error, stackTrace) => _buildFallback(context),
        );
      }
    }

    final borderRadius = widget.borderRadius;
    if (borderRadius == null) return child;

    return ClipRRect(
      clipBehavior: widget.clipBehavior,
      borderRadius: borderRadius,
      child: child,
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final placeholder = widget.placeholder;
    if (placeholder != null) return placeholder(context);
    return SizedBox(
      width: widget.size ?? widget.width,
      height: widget.size ?? widget.height,
      child: const Center(child: CircularProgressIndicator.adaptive(strokeWidth: 1.8)),
    );
  }

  Widget _buildError(BuildContext context) {
    final errorWidget = widget.errorWidget;
    if (errorWidget != null) return errorWidget(context);
    final width = widget.size ?? widget.width;
    final height = widget.size ?? widget.height;
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
    final fallbackWidget = widget.fallbackWidget;
    if (fallbackWidget != null) return fallbackWidget(context);

    // Then try the error widget
    final errorWidget = widget.errorWidget;
    if (errorWidget != null) return errorWidget(context);

    // Finally use the default error display
    return _buildError(context);
  }
}
