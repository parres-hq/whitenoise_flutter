import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

import 'chat_audio_item.dart';
import 'chat_reply_item.dart';
import 'reaction/stacked_reactions.dart';

class MessageWidget extends StatelessWidget {
  final MessageModel message;
  final bool isGroupMessage;
  final bool isSameSenderAsPrevious;
  final bool isSameSenderAsNext;
  final VoidCallback? onLongPress;
  final Function(String)? onReactionTap;

  const MessageWidget({
    super.key,
    required this.message,
    required this.isGroupMessage,
    required this.isSameSenderAsPrevious,
    required this.isSameSenderAsNext,
    this.onLongPress,
    this.onReactionTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 0.8.sw, minWidth: 0.3.sw),
          child: Padding(
            padding: EdgeInsets.only(bottom: isSameSenderAsPrevious ? 1.w : 8.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Sender avatar for group messages
                if (isGroupMessage && !message.isMe && !isSameSenderAsNext)
                  Padding(
                    padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15.r),
                      child: CachedNetworkImage(
                        imageUrl: message.sender.imagePath ?? '',
                        width: 30.w,
                        height: 30.h,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) =>
                                Container(width: 30.w, height: 30.h, color: AppColors.glitch950.withValues(alpha: 0.1)),
                        errorWidget:
                            (context, url, error) =>
                                Icon(CarbonIcons.user_avatar, size: 30.w, color: AppColors.glitch50),
                      ),
                    ),
                  )
                else if (isGroupMessage && !message.isMe)
                  SizedBox(width: 38.w),
                // Message content
                Expanded(
                  child: Column(
                    crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      // Sender name for group messages
                      if (isGroupMessage && !message.isMe && !isSameSenderAsPrevious)
                        Padding(
                          padding: EdgeInsets.only(bottom: 4.h, left: 4.w),
                          child: Text(
                            message.sender.name,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Theme.of(context).colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      // Message bubble with reactions
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Message content
                          buildMessageContent(context),
                          // Reactions
                          if (message.reactions.isNotEmpty)
                            Positioned(
                              bottom: 0.h,
                              left: message.isMe ? 12.w : null,
                              right: message.isMe ? null : 12.w,
                              child: StackedReactions(reactions: message.reactions, onReactionTap: onReactionTap),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMessageContent(BuildContext context) {
    final borderRadius =
        message.isMe
            ? isSameSenderAsPrevious
                ? BorderRadius.all(Radius.circular(6.r))
                : BorderRadius.only(
                  topLeft: Radius.circular(6.r),
                  topRight: Radius.circular(6.r),
                  bottomLeft: Radius.circular(6.r),
                )
            : isSameSenderAsPrevious
            ? BorderRadius.all(Radius.circular(6.r))
            : BorderRadius.only(
              topLeft: Radius.circular(6.r),
              topRight: Radius.circular(6.r),
              bottomRight: Radius.circular(6.r),
            );

    final cardColor = message.isMe ? AppColors.glitch950 : AppColors.glitch80;
    final textColor = message.isMe ? AppColors.glitch50 : AppColors.glitch900;

    return Container(
      decoration: BoxDecoration(borderRadius: borderRadius),
      padding: EdgeInsets.only(bottom: message.reactions.isNotEmpty ? 18.h : 0.w),
      child: Container(
        decoration: BoxDecoration(borderRadius: borderRadius, color: cardColor),
        padding: EdgeInsets.only(top: 10.w, left: 10.w, right: 10.w, bottom: 10.w),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reply message
              if (message.replyTo != null)
                ChatReplyItem(
                  message: message.replyTo!,
                  isMe: message.isMe,
                  isOriginalUser: message.replyTo!.sender.id == message.sender.id,
                ),

              // Image message
              if (message.type == MessageType.image && message.imageUrl != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: CachedNetworkImage(
                      imageUrl: message.imageUrl!,
                      width: 0.6.sw,
                      height: 0.3.sh,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => Container(
                            height: 0.4.sh,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                            child: Center(child: CircularProgressIndicator(color: AppColors.glitch50)),
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            height: 0.4.sh,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                            child: Icon(CarbonIcons.no_image, color: AppColors.glitch50, size: 40.w),
                          ),
                    ),
                  ),
                ),
              // Audio message
              if (message.type == MessageType.audio && message.audioPath != null)
                ChatAudioItem(audioPath: message.audioPath!, isMe: message.isMe),

              // Text content (for text messages or captions)
              if ((message.type == MessageType.text || (message.content != null && message.content!.isNotEmpty)) &&
                  message.type != MessageType.audio)
                Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Container(
                    alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            message.content ?? '',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: textColor,
                              decoration: TextDecoration.none,
                              fontFamily: 'OverusedGrotesk',
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                        if (message.content!.length < 32)
                          Row(
                            children: [
                              Gap(6.w),
                              Text(
                                message.timeSent,
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: textColor.withValues(alpha:0.7),
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              Gap(4.w),
                              if (message.isMe)
                                Icon(
                                  _getStatusIcon(message.status),
                                  size: 12.w,
                                  color: _getStatusColor(message.status, context),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              //Message status and time - now properly aligned to bottom right
              if ((message.content != null && message.content!.isNotEmpty && message.content!.length >= 32) ||
                  message.type == MessageType.audio)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.timeSent,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: textColor.withValues(alpha:0.7),
                        decoration: TextDecoration.none,
                      ),
                    ),
                    Gap(4.w),
                    if (message.isMe)
                      Icon(_getStatusIcon(message.status), size: 12.w, color: _getStatusColor(message.status, context)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return CarbonIcons.time;
      case MessageStatus.sent:
        return CarbonIcons.checkmark_outline;
      case MessageStatus.delivered:
        return CarbonIcons.checkmark_outline;
      case MessageStatus.read:
        return CarbonIcons.checkmark_filled;
      case MessageStatus.failed:
        return CarbonIcons.warning;
    }
  }

  Color _getStatusColor(MessageStatus status, BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return AppColors.glitch50.withValues(alpha:0.5);
      case MessageStatus.sent:
        return AppColors.glitch50.withValues(alpha:0.7);
      case MessageStatus.delivered:
        return AppColors.glitch50;
      case MessageStatus.read:
        return AppColors.glitch100;
      case MessageStatus.failed:
        return Theme.of(context).colorScheme.error;
    }
  }
}
