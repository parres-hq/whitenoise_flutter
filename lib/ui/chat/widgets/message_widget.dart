import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:whitenoise/config/providers/localization_provider.dart';
import 'package:whitenoise/config/states/chat_search_state.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/chat/widgets/chat_bubble/bubble.dart';
import 'package:whitenoise/ui/chat/widgets/media_modal.dart';
import 'package:whitenoise/ui/chat/widgets/message_media_grid.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/message_utils.dart';

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
  final SearchMatch? currentActiveMatch;
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
    final messageContentStack = Stack(
      clipBehavior: Clip.none,
      children: [
        ChatMessageBubble(
          isSender: message.isMe,
          color: message.isMe ? context.colors.meChatBubble : context.colors.otherChatBubble,
          tail: !isSameSenderAsPrevious,
          child: _buildMessageContent(context),
        ),
        if (message.reactions.isNotEmpty)
          Positioned(
            bottom: -10.h,
            left: message.isMe ? 4.w : null,
            right: message.isMe ? null : 4.w,
            child: ReactionsRow(
              message: message,
              onReactionTap: onReactionTap,
              bubbleColor:
                  message.isMe ? context.colors.meChatBubble : context.colors.otherChatBubble,
            ),
          ),
      ],
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          top: isSameSenderAsPrevious ? 4.w : 12.w,
          bottom: message.reactions.isNotEmpty ? 12.w : 0,
        ),
        child: Row(
          mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Always reserve space for avatar in group messages to keep tails aligned
            if (isGroupMessage && !message.isMe) ...[
              if (!isSameSenderAsPrevious) ...[
                WnAvatar(
                  imageUrl: message.sender.imagePath ?? '',
                  size: 32.w,
                  displayName: message.sender.displayName,
                ),
                Gap(4.w),
              ] else ...[
                // Add spacer to maintain consistent tail alignment
                SizedBox(width: 32.w + 4.w), // Same width as avatar + gap
              ],
            ],
            messageContentStack,
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicWidth(
          child: Container(
            constraints: BoxConstraints(
              // This allows the bubble to dynamically and correctly adjust its width.
              maxWidth: constraints.maxWidth,
            ),
            padding: EdgeInsets.only(
              right: message.isMe ? 8.w : 0,
              left: message.isMe ? 0 : 8.w,
              bottom: message.reactions.isNotEmpty ? 8.h : 0,
            ),
            child: Column(
              crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGroupMessage && !isSameSenderAsPrevious && !message.isMe) ...[
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
                if (message.mediaAttachments.isNotEmpty) ...[
                  MessageMediaGrid(
                    mediaFiles: message.mediaAttachments,
                    onMediaTap: (index) => _handleMediaTap(context, index),
                  ),
                  Gap(4.h),
                ],
                _buildMessageWithTimestamp(
                  context,
                  constraints.maxWidth - 16.w,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageWithTimestamp(BuildContext context, double maxWidth) {
    final textStyle = TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeight.w500,
      color: message.isMe ? context.colors.meChatBubbleText : context.colors.otherChatBubbleText,
    );

    final messageContent = message.content ?? '';
    final timestampWidth = _getTimestampWidth(context);
    final minPadding = 8.w;

    // If message content is empty, just show the timestamp
    if (messageContent.isEmpty) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TimeAndStatus(message: message, context: context),
        ],
      );
    }

    final textWidget = _buildHighlightedText(messageContent, textStyle, context);

    final textPainter = TextPainter(
      text: TextSpan(text: messageContent, style: textStyle),
      textDirection: Directionality.of(context),
    );

    textPainter.layout(maxWidth: maxWidth);
    final lines = textPainter.computeLineMetrics();

    if (lines.isNotEmpty) {
      final lastLineWidth = lines.last.width;
      final availableWidth = maxWidth - lastLineWidth;
      final canFitInline = lines.length == 1 && availableWidth >= (timestampWidth + minPadding);

      if (canFitInline) {
        return Row(
          mainAxisSize: MainAxisSize.min,
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
          children: [
            TimeAndStatus(message: message, context: context),
          ],
        ),
      ],
    );
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
      textDirection: Directionality.of(context),
    );

    textPainter.layout();
    final statusIconWidth = message.isMe ? (8.w + 14.w) : 0;
    return textPainter.width + statusIconWidth;
  }

  void _handleMediaTap(BuildContext context, int index) {
    showDialog(
      context: context,
      barrierColor: context.colors.overlay.withValues(alpha: 0.5),
      builder:
          (context) => MediaModal(
            mediaFiles: message.mediaAttachments,
            initialIndex: index,
            senderName: message.sender.displayName,
            senderImagePath: message.sender.imagePath,
            timestamp: message.createdAt,
          ),
    );
  }
}

class ReactionsRow extends StatelessWidget {
  const ReactionsRow({
    super.key,
    required this.message,
    required this.onReactionTap,
    required this.bubbleColor,
  });

  final MessageModel message;
  final Function(String p1)? onReactionTap;
  final Color bubbleColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4.w,
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
              onTap: () {
                onReactionTap?.call(emoji);
              },
              child: Container(
                height: 20.h,
                padding: EdgeInsets.symmetric(horizontal: 7.w),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.circular(999.r),
                  border: Border.all(
                    color: context.colors.surface,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Platform.isIOS
                        ? Transform.translate(
                          offset: const Offset(1, -1),
                          child: Text(
                            emoji,
                            style: TextStyle(
                              fontSize: 13.sp,
                              height: 1.0,
                              color:
                                  message.isMe
                                      ? context.colors.meChatBubbleText
                                      : context.colors.otherChatBubbleText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                        : Text(
                          emoji,
                          style: TextStyle(
                            fontSize: 13.sp,
                            height: 1.0,
                            color:
                                message.isMe
                                    ? context.colors.meChatBubbleText
                                    : context.colors.otherChatBubbleText,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    if (count > 1)
                      Platform.isIOS
                          ? Transform.translate(
                            offset: const Offset(1, -1),
                            child: Text(
                              ' ${count > 99 ? '99+' : count}',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                color:
                                    message.isMe
                                        ? context.colors.meChatBubbleText
                                        : context.colors.otherChatBubbleText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                          : Text(
                            ' ${count > 99 ? '99+' : count}',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              height: 1.0,
                              color:
                                  message.isMe
                                      ? context.colors.meChatBubbleText
                                      : context.colors.otherChatBubbleText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ],
                ),
              ),
            );
          }).toList();
        })(),
        if (message.reactions.length > 3)
          Text(
            '...',
            style: TextStyle(
              fontSize: 13.sp,
              color:
                  message.isMe
                      ? context.colors.meChatBubbleText
                      : context.colors.otherChatBubbleText,
            ),
          ),
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
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.mutedForeground,
          ),
        ),
        if (message.isMe) ...[
          Gap(8.w),
          WnImage(
            message.status.imagePath,
            size: 14.w,
            color: message.status.bubbleStatusColor(context),
          ),
        ],
      ],
    );
  }
}

class ReplyBox extends ConsumerWidget {
  const ReplyBox({super.key, this.replyingTo, this.onTap});
  final MessageModel? replyingTo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch localization changes
    ref.watch(currentLocaleProvider);
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
                  MessageUtils.getDisplayName(replyingTo, null),
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
