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
  const MessageWidget({
    super.key,
    required this.message,
    required this.isGroupMessage,
    required this.isSameSenderAsPrevious,
    required this.isSameSenderAsNext,
    this.onLongPress,
    this.onReact,
  });

  final MessageModel message;
  final bool isGroupMessage;
  final bool isSameSenderAsPrevious;
  final bool isSameSenderAsNext;
  final VoidCallback? onLongPress;
  // final Function(String)? onReact;
  final VoidCallback? onReact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 0.8.sw, minWidth: 0.3.sw),
          child: Padding(
            padding: EdgeInsets.only(bottom: isSameSenderAsPrevious ? 1.h : 8.h),
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
                                Container(width: 30.w, height: 30.h, color: AppColors.color202320.withOpacity(0.1)),
                        errorWidget:
                            (context, url, error) =>
                                Icon(CarbonIcons.user_avatar, size: 30.w, color: AppColors.colorE2E2E2),
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
                            style: TextStyle(fontSize: 12.sp, color: AppColors.red1, fontWeight: FontWeight.w600),
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
                              bottom: -10.h,
                              left: message.isMe ? null : -4.w,
                              right: message.isMe ? -4.w : null,
                              child: StackedReactions(reactions: message.reactions, onReact: onReact),
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
            ? BorderRadius.only(
              topLeft: Radius.circular(6.r),
              topRight: Radius.circular(6.r),
              bottomLeft: Radius.circular(6.r),
            )
            : BorderRadius.only(
              topLeft: Radius.circular(6.r),
              topRight: Radius.circular(6.r),
              bottomRight: Radius.circular(6.r),
            );

    final cardColor = message.isMe ? AppColors.color202320 : AppColors.colorE2E2E2;
    final textColor = message.isMe ? AppColors.colorE2E2E2 : AppColors.color202320;

    return Container(
      decoration: BoxDecoration(borderRadius: borderRadius, color: cardColor),
      padding: EdgeInsets.all(10.w),
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
                          color: AppColors.color202320.withOpacity(0.1),
                          child: Center(child: CircularProgressIndicator(color: AppColors.colorE2E2E2)),
                        ),
                    errorWidget:
                        (context, url, error) => Container(
                          height: 0.4.sh,
                          color: AppColors.color202320.withOpacity(0.1),
                          child: Icon(CarbonIcons.no_image, color: AppColors.colorE2E2E2, size: 40.w),
                        ),
                  ),
                ),
              ),
            // Audio message
            if (message.type == MessageType.audio && message.audioPath != null)
              ChatAudioItem(audioPath: message.audioPath!),

            // Text content (for text messages or captions)
            if ((message.type == MessageType.text || (message.content != null && message.content!.isNotEmpty)) &&
                message.type != MessageType.audio)
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Container(
                  alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(message.content ?? '', style: TextStyle(fontSize: 14.sp, color: textColor)),
                ),
              ),
            // Message status and time - now properly aligned to bottom right
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message.timeSent, style: TextStyle(fontSize: 10.sp, color: textColor.withOpacity(0.7))),
                Gap(4.w),
                if (message.isMe)
                  Icon(_getStatusIcon(message.status), size: 12.w, color: _getStatusColor(message.status, context)),
              ],
            ),
          ],
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
        return AppColors.colorE2E2E2.withOpacity(0.5);
      case MessageStatus.sent:
        return AppColors.colorE2E2E2.withOpacity(0.7);
      case MessageStatus.delivered:
        return AppColors.colorE2E2E2;
      case MessageStatus.read:
        return AppColors.white1;
      case MessageStatus.failed:
        return AppColors.red1;
    }
  }
}
