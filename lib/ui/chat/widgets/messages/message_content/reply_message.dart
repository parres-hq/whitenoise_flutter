import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/core/themes/colors.dart';

class ReplyMessage extends StatelessWidget {
  final MessageModel message;
  final bool isOriginalUser;

  const ReplyMessage({super.key, required this.message, this.isOriginalUser = false});

  @override
  Widget build(BuildContext context) {
    final borderColor = message.isMe ? AppColors.glitch400 : AppColors.glitch800;
    final backgroundColor = message.isMe ? AppColors.glitch80 : AppColors.glitch600;
    final textColor = message.isMe ? AppColors.glitch950 : AppColors.glitch50;
    final senderNameColor = textColor;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        // TODO: Add scroll to original message functionality
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.all(8.w),
        constraints: BoxConstraints(maxHeight: 0.2.sh),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4.r),
          border: Border(left: BorderSide(color: borderColor, width: 3.w)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sender info row
            Row(
              children: [
                // Sender avatar for group messages
                if (message.sender.imagePath != null)
                  Padding(
                    padding: EdgeInsets.only(right: 6.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.r),
                      child: CachedNetworkImage(
                        imageUrl: message.sender.imagePath!,
                        width: 16.w,
                        height: 16.h,
                        fit: BoxFit.cover,
                        placeholder:
                            (context, url) => Container(
                              width: 16.w,
                              height: 16.h,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            ),
                      ),
                    ),
                  ),
                // Sender name
                Flexible(
                  child: Text(
                    message.sender.name,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: senderNameColor,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            // Message content preview
            Flexible(child: _buildContentPreview(message, textColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildContentPreview(MessageModel message, Color textColor) {
    switch (message.type) {
      case MessageType.text:
        return Text(
          message.content ?? '',
          maxLines: 2,
          style: TextStyle(fontSize: 12.sp, color: textColor, overflow: TextOverflow.ellipsis),
        );
      case MessageType.image:
        return Row(
          children: [
            Icon(CarbonIcons.image, size: 14.w, color: textColor),
            SizedBox(width: 4.w),
            Text('Photo', style: TextStyle(fontSize: 12.sp, color: textColor, fontStyle: FontStyle.italic)),
          ],
        );
      case MessageType.audio:
        return Row(
          children: [
            Icon(CarbonIcons.document_audio, size: 14.w, color: textColor),
            SizedBox(width: 4.w),
            Text('Audio message', style: TextStyle(fontSize: 12.sp, color: textColor, fontStyle: FontStyle.italic)),
          ],
        );
      case MessageType.video:
        return Row(
          children: [
            Icon(CarbonIcons.video, size: 14.w, color: textColor),
            SizedBox(width: 4.w),
            Text('Video', style: TextStyle(fontSize: 12.sp, color: textColor, fontStyle: FontStyle.italic)),
          ],
        );
      case MessageType.file:
        return Row(
          children: [
            Icon(CarbonIcons.document, size: 14.w, color: textColor),
            SizedBox(width: 4.w),
            Text('File', style: TextStyle(fontSize: 12.sp, color: textColor, fontStyle: FontStyle.italic)),
          ],
        );
    }
  }
}
