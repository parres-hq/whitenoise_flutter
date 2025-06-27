import 'package:flutter/material.dart';
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

class _SwipeToReplyWidgetState extends State<SwipeToReplyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _dragExtent = 0.0;
  final double _dragThreshold = 60.0;
  bool _showReplyIcon = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _showReplyIcon = true;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if ((!widget.message.isMe && details.delta.dx > 0) ||
        (widget.message.isMe && details.delta.dx < 0)) {
      setState(() {
        if (widget.message.isMe) {
          _dragExtent -= details.delta.dx;
        } else {
          _dragExtent += details.delta.dx;
        }
        _dragExtent = _dragExtent.clamp(0.0, _dragThreshold);
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragExtent >= _dragThreshold * 0.5) {
      widget.onReply();
    }

    _controller.value = 0.0;
    setState(() {
      _dragExtent = 0.0;
      _showReplyIcon = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dragOffset = widget.message.isMe ? -_dragExtent : _dragExtent;

    return Stack(
      children: [
        if (_showReplyIcon)
          Positioned(
            left: widget.message.isMe ? null : 8.w,
            right: widget.message.isMe ? 8.w : null,
            top: 0,
            bottom: widget.message.reactions.isNotEmpty ? 18.h : 0,
            child: Align(
              child: Icon(
                CarbonIcons.reply,
                color: context.colors.primary,
                size: 14.w,
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