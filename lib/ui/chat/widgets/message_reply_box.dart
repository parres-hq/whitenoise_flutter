import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:whitenoise/config/providers/localization_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/chat/widgets/message_media_tile.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/utils/message_utils.dart';

class MessageReplyBox extends ConsumerWidget {
  const MessageReplyBox({super.key, this.replyingTo, this.onTap});
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
            child: Row(
              children: [
                if (replyingTo?.mediaAttachments.isNotEmpty ?? false) ...[
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: MessageMediaTile(
                      mediaFile: replyingTo!.mediaAttachments.first,
                      size: 32.w,
                    ),
                  ),
                ],
                Expanded(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
