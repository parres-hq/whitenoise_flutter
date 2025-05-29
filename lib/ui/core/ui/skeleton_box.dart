import 'package:flutter/material.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;
  final Color? baseColor;
  final Color? highlightColor;

  const SkeletonBox(
    this.width,
    this.height, {
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.baseColor,
    this.highlightColor,
    super.key,
  });

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? AppColors.glitch800.withValues(alpha: 0.4);
    final highlightColor = widget.highlightColor ?? AppColors.glitch800.withValues(alpha: 0.2);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle ? widget.borderRadius ?? BorderRadius.circular(4) : null,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: const [0.0, 0.5, 1.0],
              tileMode: TileMode.clamp,
              transform: _SlidingGradientTransform(
                slidePercent: _controller.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
