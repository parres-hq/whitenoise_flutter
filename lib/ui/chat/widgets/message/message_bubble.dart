import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/chat/widgets/message/message_status.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

import 'message_content/text_message.dart';
import 'message_content/image_message.dart';
import 'message_content/audio_message.dart';
import 'message_content/reply_message.dart';
import 'message_reactions.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isGroupMessage;
  final bool isSameSenderAsPrevious;
  final Function(String)? onReactionTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isGroupMessage,
    required this.isSameSenderAsPrevious,
    this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (isGroupMessage && !message.isMe && !isSameSenderAsPrevious) _buildSenderName(context),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: _getMessageBorderRadius(),
              ),
              padding: EdgeInsets.only(
                bottom: message.reactions.isNotEmpty ? 18.h : 0.w,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: _getMessageBorderRadius(),
                  color: message.isMe ? AppColors.glitch950 : AppColors.glitch80,
                ),
                padding: EdgeInsets.all(10.w),
                child: IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.replyTo != null) ReplyMessage(message: message),
                      if (message.type == MessageType.image && message.imageUrl != null) ImageMessage(message: message),
                      if (message.type == MessageType.audio && message.audioPath != null)
                        AudioMessage(
                          message: message,
                        ),
                      if (message.content != null && message.content!.isNotEmpty) TextMessage(message: message),
                      if ((message.content != null && message.content!.length >= 32) || message.type == MessageType.audio)
                        MessageStatusWidget(message: message),
                    ],
                  ),
                ),
              ),
            ),
            if (message.content != null && message.content!.length < 32 && message.type != MessageType.audio)
              Positioned(
                bottom: message.reactions.isNotEmpty? 34.h: 16.h,
                right: 8.w,
                child: MessageStatusWidget(message: message),
              ),
            if (message.reactions.isNotEmpty)
              Positioned(
                bottom: 0.h,
                left: message.isMe ? 12.w : null,
                right: message.isMe ? null : 12.w,
                child: MessageReactions(
                  reactions: message.reactions,
                  onReactionTap: onReactionTap,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSenderName(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h, left: 4.w),
      child: Text(
        message.sender.name,
        style: TextStyle(
          fontSize: 12.sp,
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  BorderRadius _getMessageBorderRadius() {
    if (message.isMe) {
      return isSameSenderAsPrevious
          ? BorderRadius.all(Radius.circular(6.r))
          : BorderRadius.only(
            topLeft: Radius.circular(6.r),
            topRight: Radius.circular(6.r),
            bottomLeft: Radius.circular(6.r),
          );
    } else {
      return isSameSenderAsPrevious
          ? BorderRadius.all(Radius.circular(6.r))
          : BorderRadius.only(
            topLeft: Radius.circular(6.r),
            topRight: Radius.circular(6.r),
            bottomRight: Radius.circular(6.r),
          );
    }
  }
}
