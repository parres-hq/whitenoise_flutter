import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/chat/widgets/message_media_tile.dart';
import 'package:whitenoise/ui/core/themes/assets.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class ChatInputReplyPreview extends StatelessWidget {
  const ChatInputReplyPreview({
    super.key,
    this.replyingTo,
    this.editingMessage,
    required this.onCancel,
  });

  final MessageModel? replyingTo;
  final MessageModel? editingMessage;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    if (replyingTo == null && editingMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(14.w).copyWith(bottom: 8.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: context.colors.secondary,
        border: Border(
          left: BorderSide(
            color: context.colors.mutedForeground,
          ),
        ),
      ),
      child: Row(
        children: [
          if (replyingTo?.mediaAttachments.isNotEmpty ?? false) ...[
            Padding(
              padding: EdgeInsets.only(right: 8.w),
              child: MessageMediaTile(
                mediaFile: replyingTo!.mediaAttachments.first,
                size: 32,
              ),
            ),
          ],
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        replyingTo?.sender.displayName ??
                            editingMessage?.sender.displayName ??
                            'shared.unknownUser'.tr(),
                        style: TextStyle(
                          color: context.colors.mutedForeground,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Gap(2.h),
                      Text(
                        replyingTo?.content ?? editingMessage?.content ?? 'chats.quoteText'.tr(),
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
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    width: 24.w,
                    height: 24.w,
                    alignment: Alignment.center,
                    child: WnImage(
                      AssetsPaths.icClose,
                      width: 16.w,
                      height: 16.w,
                      color: context.colors.mutedForeground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
