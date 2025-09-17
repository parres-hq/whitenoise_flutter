import 'package:flutter/material.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';

enum SweepDirection {
  leftToRight,
  rightToLeft,
}

class WnSkeletonContainer extends StatefulWidget {
  final double width;
  final double height;
  final Color? baseColor;
  final Color? highlightColor;
  final BoxShape shape;

  const WnSkeletonContainer({
    required this.width,
    required this.height,
    this.baseColor,
    this.highlightColor,
    this.shape = BoxShape.rectangle,
    super.key,
  });

  @override
  State<WnSkeletonContainer> createState() => _WnSkeletonContainerState();
}

class _WnSkeletonContainerState extends State<WnSkeletonContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _phase1Animation;
  late Animation<double> _phase2Animation;
  late Color _baseColor;
  late Color _highlightColor;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1352),
      vsync: this,
    );

    _phase1Animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.001,
          0.444,
          curve: Curves.easeInOut,
        ),
      ),
    );

    _phase2Animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.555,
          0.999,
          curve: Curves.easeInOut,
        ),
      ),
    );

    _startAnimation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _baseColor = widget.baseColor ?? context.colors.gray100;
    _highlightColor = widget.highlightColor ?? context.colors.gray200;
  }

  void _startAnimation() {
    _controller.addStatusListener(_onAnimationStatus);
    _controller.forward();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _controller.reset();
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: _buildAnimation,
        ),
      ),
    );
  }

  Widget _buildAnimation(BuildContext context, Widget? child) {
    return Stack(
      children: [
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _baseColor,
            shape: widget.shape,
          ),
        ),
        if (_phase1Animation.value > 0)
          ClipPath(
            clipper:
                widget.shape == BoxShape.circle
                    ? _CircularSweepClipper(
                      _phase1Animation.value,
                      widget.width,
                      SweepDirection.leftToRight,
                    )
                    : _RectangularSweepClipper(
                      _phase1Animation.value,
                      SweepDirection.leftToRight,
                    ),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: _highlightColor,
                shape: widget.shape,
              ),
            ),
          ),
        if (_phase2Animation.value > 0)
          ClipPath(
            clipper:
                widget.shape == BoxShape.circle
                    ? _CircularSweepClipper(
                      _phase2Animation.value,
                      widget.width,
                      SweepDirection.leftToRight,
                    )
                    : _RectangularSweepClipper(
                      _phase2Animation.value,
                      SweepDirection.leftToRight,
                    ),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: _baseColor,
                shape: widget.shape,
              ),
            ),
          ),
      ],
    );
  }
}

class _RectangularSweepClipper extends CustomClipper<Path> {
  final double progress;
  final SweepDirection direction;

  const _RectangularSweepClipper(this.progress, this.direction);

  @override
  Path getClip(Size size) {
    final path = Path();
    final sweepWidth = size.width * progress;

    if (direction == SweepDirection.leftToRight) {
      path.addRect(Rect.fromLTWH(0, 0, sweepWidth, size.height));
    } else {
      path.addRect(Rect.fromLTWH(size.width - sweepWidth, 0, sweepWidth, size.height));
    }

    return path;
  }

  @override
  bool shouldReclip(_RectangularSweepClipper oldClipper) {
    return oldClipper.progress != progress || oldClipper.direction != direction;
  }
}

class _CircularSweepClipper extends CustomClipper<Path> {
  final double progress;
  final double containerSize;
  final SweepDirection direction;

  const _CircularSweepClipper(this.progress, this.containerSize, this.direction);

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = containerSize / 2;
    final sweepX = size.width * progress;

    final circlePath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));

    final clipRect =
        direction == SweepDirection.leftToRight
            ? Rect.fromLTWH(0, 0, sweepX, size.height)
            : Rect.fromLTWH(size.width - sweepX, 0, sweepX, size.height);

    final rectPath = Path()..addRect(clipRect);

    return Path.combine(PathOperation.intersect, circlePath, rectPath);
  }

  @override
  bool shouldReclip(_CircularSweepClipper oldClipper) {
    return oldClipper.progress != progress ||
        oldClipper.direction != direction ||
        oldClipper.containerSize != containerSize;
  }
}
