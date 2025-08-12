import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:whitenoise/config/states/chat_search_state.dart';
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
  final SearchMatch? searchMatch;
  final bool isActiveSearchMatch;
  final SearchMatch? currentActiveMatch; // Add current active match
  final bool isSearchActive;

  const MessageWidget({
    super.key,
    required this.message,
    required this.isGroupMessage,
    required this.isSameSenderAsPrevious,
    required this.isSameSenderAsNext,
    this.onTap,
    this.onReactionTap,
    this.onReplyTap,
    this.searchMatch,
    this.isActiveSearchMatch = false,
    this.currentActiveMatch,
    this.isSearchActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          bottom: isSameSenderAsPrevious ? 4.w : 12.w,
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
        return IntrinsicWidth(
          child: Container(
            // Remove maxWidth constraint to allow bubble expansion
            padding: EdgeInsets.only(right: message.isMe ? 8.w : 0, left: message.isMe ? 0 : 8.w),
            child: Column(
              crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGroupMessage && !isSameSenderAsNext && !message.isMe) ...[
                  Text(
                    message.sender.displayName,
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
                  onTap:
                      message.replyTo != null ? () => onReplyTap?.call(message.replyTo!.id) : null,
                ),
                _buildMessageWithTimestamp(
                  context,
                  constraints.maxWidth - 16.w,
                ),

                if (message.reactions.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reactions positioned at bottom left
                      ReactionsWidget(
                        message: message,
                        onReactionTap: onReactionTap,
                      ),
                      // Timestamp positioned at bottom right
                      Padding(
                        padding: EdgeInsets.only(top: 6.h),
                        child: TimeAndStatus(message: message, context: context),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageWithTimestamp(BuildContext context, double maxWidth) {
    // Single source of truth for message text style
    final textStyle = TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      color: message.isMe ? context.colors.meChatBubbleText : context.colors.contactChatBubbleText,
    );

    final messageContent = message.content ?? '';
    final timestampWidth = _getTimestampWidth(context);
    final minPadding = 8.w;

    // Build highlighted text widget
    final textWidget = _buildHighlightedText(messageContent, textStyle, context);

    // Calculate if it's a single line message
    final textPainter = TextPainter(
      text: TextSpan(text: messageContent, style: textStyle),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: maxWidth);
    final lines = textPainter.computeLineMetrics();
    final isSingleLine = lines.length == 1;

    if (message.reactions.isEmpty) {
      if (isSingleLine) {
        final lastLineWidth = lines.last.width;
        final availableWidth = maxWidth - lastLineWidth;
        final canFitInline = availableWidth >= (timestampWidth + minPadding);

        if (canFitInline) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: textWidget,
              ),
              SizedBox(width: minPadding),
              TimeAndStatus(message: message, context: context),
            ],
          );
        }
      }

      // Fallback to separate lines when timestamp doesn't fit
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: maxWidth,
            child: textWidget,
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TimeAndStatus(message: message, context: context),
            ],
          ),
        ],
      );
    } else {
      // Messages with reactions: Display text separately and timestamp in ReactionsRow
      return IntrinsicWidth(
        child: _buildHighlightedText(message.content ?? '', textStyle, context),
      );
    }
  }

  Widget _buildHighlightedText(String text, TextStyle baseStyle, BuildContext context) {
    // No search is active, show normal text.
    if (!isSearchActive) {
      return Text(
        text,
        style: baseStyle,
      );
    }

    // Search is active, but this message has no matches. Dim the whole text.
    if (searchMatch == null || searchMatch!.textMatches.isEmpty) {
      return Text(
        text,
        style: baseStyle.copyWith(
          color: context.colors.mutedForeground,
        ),
      );
    }

    // Search is active and this message has matches. Highlight them.
    final spans = <TextSpan>[];
    int currentIndex = 0;

    final sortedMatches = List<TextMatch>.from(searchMatch!.textMatches)
      ..sort((a, b) => a.start.compareTo(b.start));

    for (final match in sortedMatches) {
      if (currentIndex < match.start) {
        spans.add(
          TextSpan(
            text: text.substring(currentIndex, match.start),
            style: baseStyle.copyWith(
              color: context.colors.mutedForeground,
            ),
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(match.start, match.end),
          style: baseStyle,
        ),
      );

      currentIndex = match.end;
    }

    if (currentIndex < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(currentIndex),
          style: baseStyle.copyWith(
            color: context.colors.mutedForeground,
          ),
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
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
}

class ReactionsWidget extends StatelessWidget {
  const ReactionsWidget({
    super.key,
    required this.message,
    required this.onReactionTap,
  });

  final MessageModel message;
  final Function(String)? onReactionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...(() {
          final reactionGroups = <String, List<Reaction>>{};
          for (final reaction in message.reactions) {
            reactionGroups.putIfAbsent(reaction.emoji, () => []).add(reaction);
          }
          final reactionWidgets = <Widget>[];

          // Add reaction bubbles
          reactionWidgets.addAll(
            reactionGroups.entries.take(3).map((entry) {
              final emoji = entry.key;
              final count = entry.value.length;
              return GestureDetector(
                onTap: () {
                  // Call the reaction tap handler to add/remove reaction
                  onReactionTap?.call(emoji);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color:
                        message.isMe
                            ? context.colors.primary.withValues(alpha: 0.1)
                            : context.colors.secondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        emoji,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color:
                              message.isMe
                                  ? context.colors.primaryForeground
                                  : context.colors.mutedForeground,
                        ),
                      ),
                      if (count > 1)
                        Padding(
                          padding: EdgeInsets.only(top: 6.h),
                          child: Text(
                            ' ${count > 99 ? '99+' : count}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color:
                                  message.isMe
                                      ? context.colors.primaryForeground
                                      : context.colors.mutedForeground,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );

          // Add spacing between reactions
          final spacedWidgets = <Widget>[];
          for (int i = 0; i < reactionWidgets.length; i++) {
            spacedWidgets.add(reactionWidgets[i]);
            if (i < reactionWidgets.length - 1) {
              spacedWidgets.add(SizedBox(width: 8.w));
            }
          }

          // Add ellipsis if there are more reactions
          if (message.reactions.length > 3) {
            if (spacedWidgets.isNotEmpty) {
              spacedWidgets.add(SizedBox(width: 8.w));
            }
            spacedWidgets.add(
              Text(
                '...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color:
                      message.isMe
                          ? context.colors.primaryForeground
                          : context.colors.mutedForeground,
                ),
              ),
            );
          }

          return spacedWidgets;
        })(),
      ],
    );
  }
}

class TimeAndStatus extends StatelessWidget {
  const TimeAndStatus({
    super.key,
    required this.message,
    required this.context,
  });

  final MessageModel message;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message.timeSent,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.mutedForeground,
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
                  replyingTo?.sender.displayName ?? '',
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
