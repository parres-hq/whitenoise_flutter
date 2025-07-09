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
  final Function(String)? onReplyTap;

  const MessageWidget({
    super.key,
    required this.message,
    required this.isGroupMessage,
    required this.isSameSenderAsPrevious,
    required this.isSameSenderAsNext,
    this.onTap,
    this.onReactionTap,
    this.onReplyTap,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth,
          ),
          padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 12.w),
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
              ReplyBox(
                replyingTo: message.replyTo,
                onTap: message.replyTo != null ? () => onReplyTap?.call(message.replyTo!.id) : null,
              ),
              _buildMessageWithTimestamp(
                context,
                constraints.maxWidth - 16.w,
              ),

              if (message.reactions.isNotEmpty) ...[
                SizedBox(height: 4.h),
                _buildReactionsRow(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageWithTimestamp(BuildContext context, double maxWidth) {
    if (message.reactions.isEmpty) {
      final messageContent = message.content ?? '';
      final timestampWidth = _getTimestampWidth(context);
      final minPadding = 12.w;
      final textStyle = TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w500,
        color:
            message.isMe ? context.colors.meChatBubbleText : context.colors.contactChatBubbleText,
      );

      final textPainter = TextPainter(
        text: TextSpan(text: messageContent, style: textStyle),
        textDirection: message.isMe ? TextDirection.rtl : TextDirection.ltr,
      );

      textPainter.layout(maxWidth: maxWidth);

      final lines = textPainter.computeLineMetrics();
      if (lines.isNotEmpty) {
        final lastLineWidth = lines.last.width;
        final availableWidth = maxWidth - lastLineWidth;
        final fitsOnLastLine = availableWidth >= (timestampWidth + minPadding);

        if (fitsOnLastLine && lines.length > 1) {
          return Column(
            crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: maxWidth,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: messageContent, style: textStyle),
                      WidgetSpan(
                        child: SizedBox(width: minPadding),
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                      ),
                      WidgetSpan(
                        child: _buildTimeAndStatus(context),
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        } else if (lines.length == 1 && fitsOnLastLine) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  messageContent,
                  style: textStyle,
                ),
              ),
              SizedBox(width: minPadding),
              _buildTimeAndStatus(context),
            ],
          );
        }
      }

      return Column(
        crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: maxWidth,
            child: Text(
              messageContent,
              style: textStyle,
              textAlign: TextAlign.start,
            ),
          ),
          SizedBox(height: 4.w),
          _buildTimeAndStatus(context),
        ],
      );
    } else {
      return SizedBox(
        width: maxWidth,
        child: Text(
          message.content ?? '',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color:
                message.isMe
                    ? context.colors.meChatBubbleText
                    : context.colors.contactChatBubbleText,
          ),
          textAlign: message.isMe ? TextAlign.end : TextAlign.start,
        ),
      );
    }
  }

  double _getTimestampWidth(BuildContext context) {
    final timestampText = message.isMe ? '${message.timeSent} ' : message.timeSent;

    final textPainter = TextPainter(
      text: TextSpan(
        text: timestampText,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final statusIconWidth = message.isMe ? (8.w + 14.w) : 0;
    return textPainter.width + statusIconWidth;
  }

  Widget _buildReactionsRow(BuildContext context) {
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
  const ReplyBox({super.key, this.replyingTo, this.onTap});
  final MessageModel? replyingTo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (replyingTo == null) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),

      child: Material(
        color: context.colors.secondary,

        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: context.colors.mutedForeground,
                  width: 3.0,
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
          ),
        ),
      ),
    );
  }
}
