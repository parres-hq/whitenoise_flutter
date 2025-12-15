import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

import 'package:whitenoise/config/states/chat_search_state.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/chat/widgets/chat_bubble/bubble.dart';
import 'package:whitenoise/ui/chat/widgets/media_modal.dart';
import 'package:whitenoise/ui/chat/widgets/message_media_grid.dart';
import 'package:whitenoise/ui/chat/widgets/message_reply_box.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/media_layout_calculator.dart';

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
          top: isSameSenderAsPrevious ? 4.h : 12.h,
          bottom: message.reactions.isNotEmpty ? 12.h : 0,
        ),
        color: Colors.transparent,
        width: double.infinity,
        child: Row(
          mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isGroupMessage && !message.isMe) ...[
              if (!isSameSenderAsPrevious) ...[
                WnAvatar(
                  imageUrl: message.sender.imagePath ?? '',
                  size: 32.w,
                  displayName: message.sender.displayName,
                  pubkey: message.sender.publicKey,
                  showBorder: true,
                ),
                Gap(4.w),
              ] else ...[
                SizedBox(width: 32.w + 4.w),
              ],
            ],
            messageContentStack,
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = screenWidth * 0.74;

    double? mediaWidth;
    if (message.mediaAttachments.isNotEmpty) {
      final layoutConfig = MediaLayoutCalculator.calculateLayout(
        message.mediaAttachments.length,
      );
      mediaWidth = layoutConfig.gridWidth.w;
    }

    final effectiveMaxWidth = mediaWidth != null ? (mediaWidth + 8.w) : maxBubbleWidth;

    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: effectiveMaxWidth,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: message.isMe ? 0 : 8.w,
            right: message.isMe ? 8.w : 0,
            top: 2.h,
            bottom: 2.h,
          ),
          child: Builder(
            builder: (context) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  if (message.replyTo != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: MessageReplyBox(
                        replyingTo: message.replyTo,
                        onTap: () => onReplyTap?.call(message.replyTo!.id),
                      ),
                    ),
                  if (message.mediaAttachments.isNotEmpty) ...[
                    MessageMediaGrid(
                      mediaFiles: message.mediaAttachments,
                      onMediaTap: (index) => _handleMediaTap(context, index),
                    ),
                    if (message.content?.isNotEmpty ?? false) Gap(4.h),
                  ],
                  if (message.content?.isNotEmpty ?? false) ...[
                    Builder(
                      builder: (context) {
                        double? mediaWidth;
                        if (message.mediaAttachments.isNotEmpty) {
                          final layoutConfig = MediaLayoutCalculator.calculateLayout(
                            message.mediaAttachments.length,
                          );
                          mediaWidth = layoutConfig.gridWidth.w;
                        }
                        return _buildMessageWithTimestamp(context, mediaWidth: mediaWidth);
                      },
                    ),
                  ] else if (message.mediaAttachments.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TimeAndStatus(message: message, context: context),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMessageWithTimestamp(BuildContext context, {double? mediaWidth}) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final maxBubbleWidth = screenWidth * 0.74;
    final maxWidth = mediaWidth ?? (maxBubbleWidth - 16.w);
    final messageContent = message.content ?? '';
    final timestampWidth = _getTimestampWidth(context);
    final minSpacing = 6.w;

    final textStyle = TextStyle(
      fontSize: 16.sp,
      height: 20.sp / 16.sp,
      fontWeight: FontWeight.w500,
      color: message.isMe ? context.colors.meChatBubbleText : context.colors.otherChatBubbleText,
    );

    final textPainter = TextPainter(
      text: TextSpan(text: messageContent, style: textStyle),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout(maxWidth: maxWidth);

    final lines = textPainter.computeLineMetrics();
    if (lines.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TimeAndStatus(message: message, context: context),
        ],
      );
    }

    final isSingleLine = lines.length == 1;
    final lastLineWidth = lines.last.width;
    final requiredSpace = timestampWidth + minSpacing;
    final availableSpace = maxWidth - lastLineWidth;
    final canFitInline =
        isSingleLine &&
        availableSpace >= requiredSpace &&
        lastLineWidth + requiredSpace <= maxWidth;
    final hasReply = message.replyTo != null;
    final hasMedia = mediaWidth != null;

    final textWidget = _buildHighlightedText(messageContent, textStyle, context);

    if (canFitInline) {
      if (hasReply || hasMedia) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
          ),
          child: Row(
            children: [
              Expanded(
                child: textWidget,
              ),
              Gap(minSpacing),
              Align(
                alignment: Alignment.centerRight,
                child: Transform.translate(
                  offset: const Offset(0, 2),
                  child: TimeAndStatus(message: message, context: context),
                ),
              ),
            ],
          ),
        );
      } else {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: textWidget,
              ),
              Gap(minSpacing),
              Transform.translate(
                offset: const Offset(0, 2),
                child: TimeAndStatus(message: message, context: context),
              ),
            ],
          ),
        );
      }
    } else {
      final textMaxWidth = lines.map((line) => line.width).reduce((a, b) => a > b ? a : b);
      final minWidth = textMaxWidth > timestampWidth ? textMaxWidth : timestampWidth;
      final isTimestampWider = timestampWidth > textMaxWidth;
      final double targetWidth = hasMedia ? mediaWidth : maxWidth;
      final double minConstraintWidth = hasMedia ? mediaWidth : minWidth;

      return ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minConstraintWidth,
          maxWidth: targetWidth,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: textWidget,
            ),
            Positioned(
              left: isTimestampWider ? 0 : null,
              right: isTimestampWider ? null : 0,
              bottom: 0,
              child: TimeAndStatus(message: message, context: context),
            ),
          ],
        ),
      );
    }
  }

  double _getTimestampWidth(BuildContext context) {
    final timestampText = message.timeSent;

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

    if (message.isMe) {
      final iconWidth = 14.w;
      final spacing = 2.w;
      return textPainter.width + spacing + iconWidth;
    }

    return textPainter.width;
  }

  Widget _buildHighlightedText(String text, TextStyle baseStyle, BuildContext context) {
    if (!isSearchActive) {
      return Text(
        text,
        style: baseStyle,
      );
    }

    if (searchMatch == null || searchMatch!.textMatches.isEmpty) {
      return Text(
        text,
        style: baseStyle.copyWith(
          color: context.colors.mutedForeground,
        ),
      );
    }

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
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: context.colors.mutedForeground,
          ),
        ),
        if (message.isMe) ...[
          Gap(2.w),
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
