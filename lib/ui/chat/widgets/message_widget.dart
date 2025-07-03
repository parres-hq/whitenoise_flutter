import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/chat/widgets/chat_bubble/bubble.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

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
      child: Container(
        margin: EdgeInsets.only(
          bottom: isSameSenderAsPrevious ? 1.w : 8.w,
        ),
        child: ChatMessageBubble(
          isSender: message.isMe,
          color: message.isMe ? context.colors.meChatBubble : context.colors.contactChatBubble,
          tail: !isSameSenderAsNext,
          child: _buildMessageContent(context),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 2.h,
      ).copyWith(
        right: 8.w,
        left: message.isMe ? 0 : 8.w,
        bottom: 8.w,
      ),
      child: Column(
        crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isGroupMessage && !isSameSenderAsNext && !message.isMe) ...[
            Text(
              message.sender.name,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: context.colors.mutedForeground,
              ),
            ),
            Gap(4.h),
          ],

          ReplyBox(replyingTo: message.replyTo),
          Text(
            message.content ?? '',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color:
                  message.isMe
                      ? context.colors.meChatBubbleText
                      : context.colors.contactChatBubbleText,
            ),
          ),

          Gap(8.h),
          _buildMetadataRow(context),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context) {
    if (message.reactions.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildTimeAndStatus(context),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...(() {
          final reactionGroups = <String, List<Reaction>>{};
          for (final reaction in message.reactions) {
            reactionGroups.putIfAbsent(reaction.emoji, () => []).add(reaction);
          }
          return reactionGroups.entries.take(3).map((entry) {
            final emoji = entry.key;
            final count = entry.value.length;
            return GestureDetector(
              onTap: () => onReactionTap?.call(emoji),
              child: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: emoji,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color:
                              message.isMe
                                  ? context.colors.primaryForeground
                                  : context.colors.mutedForeground,
                        ),
                      ),
                      TextSpan(
                        text: ' ${count > 99 ? '99+' : count}',
                        style: TextStyle(
                          fontSize: 14.sp,

                          fontWeight: FontWeight.w600,
                          color:
                              message.isMe
                                  ? context.colors.primaryForeground
                                  : context.colors.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList();
        })(),
        if (message.reactions.length > 3)
          Text(
            '...',
            style: TextStyle(
              fontSize: 14.sp,
              color:
                  message.isMe ? context.colors.primaryForeground : context.colors.mutedForeground,
            ),
          ),
        const Spacer(),
        _buildTimeAndStatus(context),
      ],
    );
  }

  Widget _buildTimeAndStatus(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.timeSent,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: message.isMe ? context.colors.primaryForeground : context.colors.mutedForeground,
          ),
        ),
        if (message.isMe) ...[
          Gap(8.w),
          Image.asset(
            message.status.imagePath,
            width: 14.w,
            height: 14.w,
            color: message.status.bubbleStatusColor(context),
          ),
        ],
      ],
    );
  }
}

class ReplyBox extends StatelessWidget {
  const ReplyBox({super.key, this.replyingTo});
  final MessageModel? replyingTo;
  @override
  Widget build(BuildContext context) {
    if (replyingTo == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: context.colors.secondary,
        border: Border(
          left: BorderSide(
            color: context.colors.mutedForeground,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            replyingTo?.sender.name ?? '',
            style: TextStyle(
              color: context.colors.mutedForeground,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Gap(4.h),
          Text(
            replyingTo?.content ?? '',
            style: TextStyle(
              color: context.colors.primary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
