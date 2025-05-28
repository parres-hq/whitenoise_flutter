// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:gap/gap.dart';
// import 'package:supa_carbon_icons/supa_carbon_icons.dart';
// import 'package:whitenoise/domain/models/message_model.dart';
// import 'package:whitenoise/ui/core/themes/colors.dart';

// import 'chat_audio_item.dart';
// import 'chat_reply_item.dart';
// import '../reaction/stacked_reactions.dart';

// class MessageWidget extends StatelessWidget {
//   final MessageModel message;
//   final bool isGroupMessage;
//   final bool isSameSenderAsPrevious;
//   final bool isSameSenderAsNext;
//   final VoidCallback? onTap;
//   final Function(String)? onReactionTap;

//   const MessageWidget({
//     super.key,
//     required this.message,
//     required this.isGroupMessage,
//     required this.isSameSenderAsPrevious,
//     required this.isSameSenderAsNext,
//     this.onTap,
//     this.onReactionTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Align(
//         alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             maxWidth: 0.8.sw,
//             minWidth: 0.3.sw,
//           ),
//           child: Padding(
//             padding: EdgeInsets.only(
//               bottom: isSameSenderAsPrevious ? 1.w : 8.w,
//             ),
//             child: _buildMessageRow(context),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildMessageRow(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.end,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         if (isGroupMessage && !message.isMe) _buildSenderAvatar(),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//             children: [
//               if (isGroupMessage && !message.isMe && !isSameSenderAsPrevious) _buildSenderName(context),
//               _buildMessageContentWithReactions(context),
//             ],
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSenderAvatar() {
//     return Padding(
//       padding: EdgeInsets.only(right: 8.w, bottom: 4.h),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(15.r),
//         child: CachedNetworkImage(
//           imageUrl: message.sender.imagePath ?? '',
//           width: 30.w,
//           height: 30.h,
//           fit: BoxFit.cover,
//           placeholder:
//               (context, url) => Container(
//                 width: 30.w,
//                 height: 30.h,
//                 color: AppColors.glitch950.withOpacity(0.1),
//               ),
//           errorWidget:
//               (context, url, error) => Icon(
//                 CarbonIcons.user_avatar,
//                 size: 30.w,
//                 color: AppColors.glitch50,
//               ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSenderName(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 4.h, left: 4.w),
//       child: Text(
//         message.sender.name,
//         style: TextStyle(
//           fontSize: 12.sp,
//           color: Theme.of(context).colorScheme.error,
//           fontWeight: FontWeight.w600,
//         ),
//       ),
//     );
//   }

//   Widget _buildMessageContentWithReactions(BuildContext context) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         _buildMessageBubble(context),
//         if (message.reactions.isNotEmpty)
//           Positioned(
//             bottom: 0.h,
//             left: message.isMe ? 12.w : null,
//             right: message.isMe ? null : 12.w,
//             child: StackedReactions(
//               reactions: message.reactions,
//               onReactionTap: onReactionTap,
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildMessageBubble(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: _getMessageBorderRadius(),
//       ),
//       padding: EdgeInsets.only(
//         bottom: message.reactions.isNotEmpty ? 18.h : 0.w,
//       ),
//       child: Container(
//         decoration: BoxDecoration(
//           borderRadius: _getMessageBorderRadius(),
//           color: message.isMe ? AppColors.glitch950 : AppColors.glitch80,
//         ),
//         padding: EdgeInsets.all(10.w),
//         child: IntrinsicWidth(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.end,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               if (message.replyTo != null) 
//                 _buildReplyItem(),
//               if (message.type == MessageType.image && message.imageUrl != null) _buildImageMessage(),
//               if (message.type == MessageType.audio && message.audioPath != null)
//                 ChatAudioItem(
//                   audioPath: message.audioPath!,
//                   isMe: message.isMe,
//                 ),
//               if (_shouldShowTextContent) _buildTextContent(context),
//               if (_shouldShowStatusSeparately) _buildMessageStatus(context),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildReplyItem() {
//     return ChatReplyItem(
//       message: message.replyTo!,
//       isMe: message.isMe,
//       isOriginalUser: message.replyTo!.sender.id == message.sender.id,
//     );
//   }

//   Widget _buildImageMessage() {
//     return Padding(
//       padding: EdgeInsets.only(bottom: 4.h),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(4.r),
//         child: CachedNetworkImage(
//           imageUrl: message.imageUrl!,
//           width: 0.6.sw,
//           height: 0.3.sh,
//           fit: BoxFit.cover,
//           placeholder:
//               (context, url) => Container(
//                 height: 0.4.sh,
//                 color: AppColors.glitch950.withOpacity(0.1),
//                 child: Center(
//                   child: CircularProgressIndicator(
//                     color: AppColors.glitch50,
//                   ),
//                 ),
//               ),
//           errorWidget:
//               (context, url, error) => Container(
//                 height: 0.4.sh,
//                 color: AppColors.glitch950.withOpacity(0.1),
//                 child: Icon(
//                   CarbonIcons.no_image,
//                   color: AppColors.glitch50,
//                   size: 40.w,
//                 ),
//               ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextContent(BuildContext context) {
//     final textColor = message.isMe ? AppColors.glitch50 : AppColors.glitch900;

//     return Padding(
//       padding: EdgeInsets.only(bottom: 4.h),
//       child: Container(
//         alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
//         child: Row(
//           children: [
//             Flexible(
//               child: Text(
//                 message.content ?? '',
//                 style: TextStyle(
//                   fontSize: 14.sp,
//                   color: textColor,
//                   decoration: TextDecoration.none,
//                   fontFamily: 'OverusedGrotesk',
//                   fontWeight: FontWeight.normal,
//                 ),
//               ),
//             ),
//             if (message.content!.length < 32) 
//               _buildInlineMessageStatus(context),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInlineMessageStatus(BuildContext context) {
//     final textColor = message.isMe ? AppColors.glitch50 : AppColors.glitch900;

//     return Row(
//       children: [
//         Gap(6.w),
//         Text(
//           message.timeSent,
//           style: TextStyle(
//             fontSize: 10.sp,
//             color: textColor.withOpacity(0.7),
//             decoration: TextDecoration.none,
//           ),
//         ),
//         Gap(4.w),
//         if (message.isMe)
//           Icon(
//             _getStatusIcon(message.status),
//             size: 12.w,
//             color: _getStatusColor(message.status, context),
//           ),
//       ],
//     );
//   }

//   Widget _buildMessageStatus(BuildContext context) {
//     final textColor = message.isMe ? AppColors.glitch50 : AppColors.glitch900;

//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           message.timeSent,
//           style: TextStyle(
//             fontSize: 10.sp,
//             color: textColor.withOpacity(0.7),
//             decoration: TextDecoration.none,
//           ),
//         ),
//         Gap(4.w),
//         if (message.isMe)
//           Icon(
//             _getStatusIcon(message.status),
//             size: 12.w,
//             color: _getStatusColor(message.status, context),
//           ),
//       ],
//     );
//   }

//   BorderRadius _getMessageBorderRadius() {
//     if (message.isMe) {
//       return isSameSenderAsPrevious
//           ? BorderRadius.all(Radius.circular(6.r))
//           : BorderRadius.only(
//             topLeft: Radius.circular(6.r),
//             topRight: Radius.circular(6.r),
//             bottomLeft: Radius.circular(6.r),
//           );
//     } else {
//       return isSameSenderAsPrevious
//           ? BorderRadius.all(Radius.circular(6.r))
//           : BorderRadius.only(
//             topLeft: Radius.circular(6.r),
//             topRight: Radius.circular(6.r),
//             bottomRight: Radius.circular(6.r),
//           );
//     }
//   }

//   bool get _shouldShowTextContent {
//     return (message.type == MessageType.text || (message.content != null && message.content!.isNotEmpty)) &&
//         message.type != MessageType.audio;
//   }

//   bool get _shouldShowStatusSeparately {
//     return (message.content != null && message.content!.isNotEmpty && message.content!.length >= 32) ||
//         message.type == MessageType.audio;
//   }

//   IconData _getStatusIcon(MessageStatus status) {
//     switch (status) {
//       case MessageStatus.sending:
//         return CarbonIcons.time;
//       case MessageStatus.sent:
//       case MessageStatus.delivered:
//         return CarbonIcons.checkmark_outline;
//       case MessageStatus.read:
//         return CarbonIcons.checkmark_filled;
//       case MessageStatus.failed:
//         return CarbonIcons.warning;
//     }
//   }

//   Color _getStatusColor(MessageStatus status, BuildContext context) {
//     switch (status) {
//       case MessageStatus.sending:
//         return AppColors.glitch50.withOpacity(0.5);
//       case MessageStatus.sent:
//         return AppColors.glitch50.withOpacity(0.7);
//       case MessageStatus.delivered:
//         return AppColors.glitch50;
//       case MessageStatus.read:
//         return AppColors.glitch100;
//       case MessageStatus.failed:
//         return Theme.of(context).colorScheme.error;
//     }
//   }
// }


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
              bottom: isSameSenderAsPrevious ? 1.w : 8.w,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isGroupMessage && !message.isMe)
                  MessageSenderInfo(
                    message: message,
                    isSameSenderAsNext: isSameSenderAsNext,
                  ),
                Expanded(
                  child: MessageBubble(
                    message: message,
                    isGroupMessage: isGroupMessage,
                    isSameSenderAsPrevious: isSameSenderAsPrevious,
                    onReactionTap: onReactionTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}