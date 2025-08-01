import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';
import 'package:whitenoise/ui/core/utils/tooltip_positioning.dart';

class WnTooltip extends StatelessWidget {
  const WnTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow = false,
    this.maxWidth,
    this.footer,
  });

  static bool _isTooltipVisible = false;
  static OverlayEntry? _currentTooltipEntry;

  final String message;
  final Widget child;
  final bool preferBelow;
  final double? maxWidth;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: '',
      decoration: const BoxDecoration(),
      richMessage: WidgetSpan(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? 280.w,
          ),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: context.colors.primary,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  color: context.colors.primaryForeground,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              if (footer != null) ...[
                Gap(16.h),
                footer!,
              ],
            ],
          ),
        ),
      ),
      preferBelow: preferBelow,
      child: child,
    );
  }

  static void show({
    required BuildContext context,
    required GlobalKey targetKey,
    required String message,
    Widget? footer,
    double? maxWidth,
  }) {
    // Prevent multiple tooltips
    if (_isTooltipVisible) return;

    final overlay = Overlay.of(context);
    final renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final tooltipMaxHeight = 200.h;

    final tooltipWidth = maxWidth ?? 280.w;
    final tooltipPosition = TooltipPositioning.calculatePosition(
      targetPosition: position,
      targetSize: size,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
      tooltipWidth: tooltipWidth,
      tooltipMaxHeight: tooltipMaxHeight,
    );

    final showBelow = tooltipPosition.showBelow;
    final tooltipLeft = tooltipPosition.tooltipLeft;
    final arrowLeft = tooltipPosition.arrowLeft;

    // Capture theme colors before creating overlay
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final primaryForegroundColor = theme.colorScheme.onPrimary;

    _currentTooltipEntry = OverlayEntry(
      builder:
          (context) => _AnimatedTooltipOverlay(
            onDismiss: () {
              try {
                _currentTooltipEntry?.remove();
                _currentTooltipEntry = null;
                _isTooltipVisible = false;
              } catch (e) {
                // Overlay already removed
              }
            },
            onNavigateBack: () {
              try {
                _currentTooltipEntry?.remove();
                _currentTooltipEntry = null;
                _isTooltipVisible = false;
              } catch (e) {
                // Overlay already removed
              }
              Navigator.of(context).pop();
            },
            tooltipLeft: tooltipLeft,
            showBelow: showBelow,
            position: position,
            size: size,
            screenHeight: screenHeight,
            tooltipWidth: tooltipWidth,
            arrowLeft: arrowLeft,
            primaryColor: primaryColor,
            primaryForegroundColor: primaryForegroundColor,
            message: message,
            footer: footer,
          ),
    );

    _isTooltipVisible = true;
    overlay.insert(_currentTooltipEntry!);
  }

  static void hide() {
    if (_isTooltipVisible && _currentTooltipEntry != null) {
      try {
        _currentTooltipEntry?.remove();
        _currentTooltipEntry = null;
        _isTooltipVisible = false;
      } catch (e) {
        // Overlay already removed
      }
    }
  }
}

class _AnimatedTooltipOverlay extends StatefulWidget {
  const _AnimatedTooltipOverlay({
    required this.onDismiss,
    required this.onNavigateBack,
    required this.tooltipLeft,
    required this.showBelow,
    required this.position,
    required this.size,
    required this.screenHeight,
    required this.tooltipWidth,
    required this.arrowLeft,
    required this.primaryColor,
    required this.primaryForegroundColor,
    required this.message,
    this.footer,
  });

  final VoidCallback onDismiss;
  final VoidCallback onNavigateBack;
  final double tooltipLeft;
  final bool showBelow;
  final Offset position;
  final Size size;
  final double screenHeight;
  final double tooltipWidth;
  final double arrowLeft;
  final Color primaryColor;
  final Color primaryForegroundColor;
  final String message;
  final Widget? footer;

  @override
  State<_AnimatedTooltipOverlay> createState() => _AnimatedTooltipOverlayState();
}

class _AnimatedTooltipOverlayState extends State<_AnimatedTooltipOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _animationController.forward();

    // Auto-dismiss with fade out animation after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _dismissWithAnimation();
      }
    });
  }

  void _dismissWithAnimation() {
    _animationController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: Stack(
                children: [
                  Positioned(
                    left: widget.tooltipLeft,
                    top: widget.showBelow ? widget.position.dy + widget.size.height + 4.h : null,
                    bottom:
                        widget.showBelow ? null : widget.screenHeight - widget.position.dy + 4.h,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Stack(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Spacer for arrow when tooltip is below
                              if (widget.showBelow) SizedBox(height: 6.h),
                              Container(
                                width: widget.tooltipWidth,
                                padding: EdgeInsets.all(16.w),
                                decoration: BoxDecoration(
                                  color: widget.primaryColor,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.message,
                                      style: TextStyle(
                                        color: widget.primaryForegroundColor,
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                      ),
                                    ),
                                    if (widget.footer != null) ...[
                                      Gap(16.h),
                                      widget.footer!,
                                    ],
                                  ],
                                ),
                              ),
                              // Spacer for arrow when tooltip is above
                              if (!widget.showBelow) SizedBox(height: 6.h),
                            ],
                          ),
                          // Arrow at top when tooltip is below target (pointing up to target)
                          if (widget.showBelow)
                            Positioned(
                              left: widget.arrowLeft,
                              top: 0,
                              child: CustomPaint(
                                size: Size(12.w, 6.h),
                                painter: _TooltipArrowPainter(
                                  pointingUp: true,
                                  arrowColor: widget.primaryColor,
                                ),
                              ),
                            ),
                          // Arrow at bottom when tooltip is above target (pointing down to target)
                          if (!widget.showBelow)
                            Positioned(
                              left: widget.arrowLeft,
                              bottom: 0,
                              child: CustomPaint(
                                size: Size(12.w, 6.h),
                                painter: _TooltipArrowPainter(
                                  arrowColor: widget.primaryColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TooltipArrowPainter extends CustomPainter {
  const _TooltipArrowPainter({
    this.pointingUp = false,
    required this.arrowColor,
  });

  final bool pointingUp;
  final Color arrowColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = arrowColor
          ..style = PaintingStyle.fill;

    final path = Path();

    if (pointingUp) {
      // Arrow pointing up (tooltip is below target)
      path.moveTo(size.width / 2, 0); // Top center (point)
      path.lineTo(0, size.height); // Bottom left
      path.lineTo(size.width, size.height); // Bottom right
    } else {
      // Arrow pointing down (tooltip is above target)
      path.moveTo(size.width / 2, size.height); // Bottom center (point)
      path.lineTo(0, 0); // Top left
      path.lineTo(size.width, 0); // Top right
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
