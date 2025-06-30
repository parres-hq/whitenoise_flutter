import 'package:flutter/material.dart';
import 'package:whitenoise/ui/chat/widgets/chat_bubble/painter.dart';
import 'package:whitenoise/ui/core/themes/src/app_theme.dart';

class ChatMessageBubble extends StatelessWidget {
  final bool isSender;
  final Widget child;
  final bool tail;
  final Color? color;
  final BoxConstraints? constraints;

  const ChatMessageBubble({
    super.key,
    this.isSender = true,
    this.constraints,
    required this.child,
    this.tail = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 8.w),
            child: CustomPaint(
              painter: CustomChatBubbleNoBorderPainter(
                color: color ?? context.colors.meChatBubble,
                alignment: isSender ? Alignment.topRight : Alignment.topLeft,
                tail: tail,
              ),
              child: Container(
                constraints:
                    constraints ??
                    BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                margin:
                    isSender
                        ? EdgeInsets.fromLTRB(16.w, 7.h, 17.w, 7.h)
                        : EdgeInsets.fromLTRB(17.w, 7.h, 7.w, 7.h),
                child: child,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
