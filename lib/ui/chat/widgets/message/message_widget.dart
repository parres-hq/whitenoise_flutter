import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/domain/models/message_model.dart';

import 'message_bubble.dart';
import 'message_sender_info.dart';

class MessageWidget extends StatelessWidget {
  final MessageModel message;
  final bool isGroupMessage;
  final bool isSameSenderAsPrevious;
  final bool isSameSenderAsNext;
  final VoidCallback? onTap;
  final Function(String)? onReactionTap;

  const MessageWidget({
    super.key,
    required this.message,
    required this.isGroupMessage,
    required this.isSameSenderAsPrevious,
    required this.isSameSenderAsNext,
    this.onTap,
    this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Align(
        alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 0.8.sw,
            minWidth: 0.3.sw,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: isSameSenderAsPrevious ? 1.h : 8.h,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGroupMessage && !message.isMe)
                  MessageSenderInfo(
                    message: message,
                    isSameSenderAsNext: isSameSenderAsNext,
                    isSameSenderAsPrevious: isSameSenderAsPrevious,
                  ),
                MessageBubble(
                  message: message,
                  isGroupMessage: isGroupMessage,
                  isSameSenderAsPrevious: isSameSenderAsPrevious,
                  isSameSenderAsNext: isSameSenderAsNext,
                  onReactionTap: onReactionTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
