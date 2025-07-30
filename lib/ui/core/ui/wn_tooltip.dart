import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';

class WnTooltip extends StatelessWidget {
  const WnTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow = false,
    this.maxWidth,
    this.footer,
  });

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
    final overlay = Overlay.of(context);
    final renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final tooltipMaxHeight = 200.h;

    // Check if there's enough space below the target
    final spaceBelow = screenHeight - (position.dy + size.height);
    final showBelow = spaceBelow >= tooltipMaxHeight;

    // Calculate tooltip width and position
    final tooltipWidth = maxWidth ?? 280.w;
    final tooltipLeft = (position.dx + size.width / 2 - tooltipWidth / 2)
        .clamp(16.w, screenWidth - tooltipWidth - 16.w);
    
    // Calculate arrow position relative to tooltip
    final targetCenter = position.dx + size.width / 2;
    final arrowLeft = (targetCenter - tooltipLeft - 6.w).clamp(12.w, tooltipWidth - 12.w);

    // Capture theme colors before creating overlay
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final primaryForegroundColor = theme.colorScheme.onPrimary;

    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder:
          (context) => GestureDetector(
            onTap: () {
              try {
                overlayEntry?.remove();
                overlayEntry = null;
              } catch (e) {
                // Overlay already removed
              }
            },
            behavior: HitTestBehavior.translucent,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  Positioned(
                    left: tooltipLeft,
                    top: showBelow ? position.dy + size.height + 4.h : null,
                    bottom: showBelow ? null : screenHeight - position.dy + 4.h,
                    child: Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Spacer for arrow when tooltip is below
                            if (showBelow) SizedBox(height: 6.h),
                            Container(
                              width: tooltipWidth,
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: primaryColor,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message,
                                    style: TextStyle(
                                      color: primaryForegroundColor,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                  if (footer != null) ...[
                                    Gap(16.h),
                                    footer,
                                  ],
                                ],
                              ),
                            ),
                            // Spacer for arrow when tooltip is above
                            if (!showBelow) SizedBox(height: 6.h),
                          ],
                        ),
                        // Arrow at top when tooltip is below target (pointing up to target)
                        if (showBelow)
                          Positioned(
                            left: arrowLeft,
                            top: 0,
                            child: CustomPaint(
                              size: Size(12.w, 6.h),
                              painter: _TooltipArrowPainter(
                                pointingUp: true,
                                arrowColor: primaryColor,
                              ),
                            ),
                          ),
                        // Arrow at bottom when tooltip is above target (pointing down to target)
                        if (!showBelow)
                          Positioned(
                            left: arrowLeft,
                            bottom: 0,
                            child: CustomPaint(
                              size: Size(12.w, 6.h),
                              painter: _TooltipArrowPainter(
                                arrowColor: primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry!);

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      try {
        overlayEntry?.remove();
        overlayEntry = null;
      } catch (e) {
        // Overlay already removed
      }
    });
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
