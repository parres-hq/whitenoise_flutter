import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
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
  static const double _dragThreshold = 60.0;
  static const double _hapticThreshold = _dragThreshold * 0.5;
  static const double _maxDragExtent = _dragThreshold * 1.2;
  bool _showReplyIcon = false;
  bool _hapticTriggered = false;
  bool _canUndo = false;

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _showReplyIcon = true;
      _canUndo = false;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final delta = details.delta.dx;
    if (delta > 0 || (delta < 0 && _dragExtent > 0)) {
      final newDragExtent = (_dragExtent + delta).clamp(0.0, _maxDragExtent);

      final crossedThreshold = _dragExtent >= _hapticThreshold;
      final belowThreshold = newDragExtent < _hapticThreshold;

      setState(() {
        _dragExtent = newDragExtent;

        if (newDragExtent >= _hapticThreshold && !_hapticTriggered) {
          HapticFeedback.lightImpact();
          _hapticTriggered = true;
        } else if (belowThreshold) {
          if (crossedThreshold) _canUndo = true;
          _hapticTriggered = false;
        }
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragExtent >= _hapticThreshold && !_canUndo) {
      widget.onReply();
    }
    _resetState();
  }

  void _resetState() {
    setState(() {
      _dragExtent = 0.0;
      _showReplyIcon = false;
      _hapticTriggered = false;
      _canUndo = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_showReplyIcon) _buildReplyIcon(context),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: widget.onTap,
            onHorizontalDragStart: _handleDragStart,
            onHorizontalDragUpdate: _handleDragUpdate,
            onHorizontalDragEnd: _handleDragEnd,
            child: Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReplyIcon(BuildContext context) {
    return Positioned(
      left: 8.w,
      top: 0,
      bottom: widget.message.reactions.isNotEmpty ? 18.h : 0,
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedScale(
          scale: _dragExtent > _hapticThreshold ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              AssetsPaths.icReply,
              colorFilter: ColorFilter.mode(
                context.colors.primary,
                BlendMode.srcIn,
              ),
              width: 16.w,
              height: 16.w,
            ),
          ),
        ),
      ),
    );
  }
}
