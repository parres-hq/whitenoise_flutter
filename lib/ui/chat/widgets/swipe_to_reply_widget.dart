import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

class SwipeToReplyWidget extends StatefulWidget {
  final MessageModel message;
  final VoidCallback onReply;
  final VoidCallback onTap;
  final Widget child;

  const SwipeToReplyWidget({
    super.key,
    required this.message,
    required this.onReply,
    required this.onTap,
    required this.child,
  });

  @override
  State<SwipeToReplyWidget> createState() => _SwipeToReplyWidgetState();
}

class _SwipeToReplyWidgetState extends State<SwipeToReplyWidget> {
  double _dragExtent = 0.0;
  final double _dragThreshold = 60.0;
  bool _showReplyIcon = false;
  bool _hapticTriggered = false;

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _showReplyIcon = true;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (details.delta.dx > 0) {
      setState(() {
        _dragExtent += details.delta.dx;
        _dragExtent = _dragExtent.clamp(
          0.0,
          _dragThreshold * 1.2,
        );

        if (_dragExtent >= _dragThreshold * 0.5 && !_hapticTriggered) {
          HapticFeedback.lightImpact();
          _hapticTriggered = true;
        }
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragExtent >= _dragThreshold * 0.5) {
      widget.onReply();
    }

    setState(() {
      _dragExtent = 0.0;
      _showReplyIcon = false;
      _hapticTriggered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dragOffset = _dragExtent;
    return Stack(
      children: [
        if (_showReplyIcon)
          Positioned(
            left: 8.w,
            top: 0,
            bottom: widget.message.reactions.isNotEmpty ? 18.h : 0,
            child: Align(
              alignment: Alignment.centerLeft,
              child: AnimatedScale(
                scale: _dragExtent > _dragThreshold * 0.5 ? 1.2 : 1.0,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: context.colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CarbonIcons.reply,
                    color: context.colors.primary,
                    size: 16.w,
                  ),
                ),
              ),
            ),
          ),
        GestureDetector(
          onTap: widget.onTap,
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: _handleDragUpdate,
          onHorizontalDragEnd: _handleDragEnd,
          child: Transform.translate(
            offset: Offset(dragOffset, 0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
