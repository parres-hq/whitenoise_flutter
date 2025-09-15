import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/chat/widgets/message_widget.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_default_data.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reaction_hero_dialog_route.dart';
import 'package:whitenoise/ui/chat/widgets/reaction/reactions_dialog_widget.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';
import 'package:whitenoise/ui/core/ui/wn_bottom_sheet.dart';

class ChatDialogService {
  static void showEmojiBottomSheet({
    required BuildContext context,
    required WidgetRef ref,
    required MessageModel message,
  }) {
    WnBottomSheet.show(
      context: context,
      showCloseButton: false,
      useSafeArea: false,
      builder: (context) {
        return Container(
          height: 0.4.sh,
          decoration: BoxDecoration(
            color: context.colors.primaryForeground,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
          ),
          child: EmojiPicker(
            config: Config(
              bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
              emojiViewConfig: EmojiViewConfig(
                backgroundColor: context.colors.primaryForeground,
                columns: 7,
                emojiSizeMax: 32.0,
                noRecents: Text(
                  'No Recents',
                  style: TextStyle(
                    fontSize: 20,
                    color: context.colors.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
                loadingIndicator: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.colors.primary,
                  ),
                ),
              ),
              categoryViewConfig: CategoryViewConfig(
                backgroundColor: context.colors.primaryForeground,
                iconColor: context.colors.mutedForeground,
                iconColorSelected: context.colors.primary,
                indicatorColor: context.colors.primary,
                backspaceColor: context.colors.mutedForeground,
              ),
              searchViewConfig: SearchViewConfig(
                backgroundColor: context.colors.primaryForeground,
                hintText: 'Search emoji',
                hintTextStyle: TextStyle(
                  color: context.colors.mutedForeground,
                ),
              ),
            ),
            onEmojiSelected: ((category, emoji) {
              Navigator.pop(context);
              ref
                  .read(chatProvider.notifier)
                  .updateMessageReaction(message: message, reaction: emoji.emoji);
            }),
          ),
        );
      },
    );
  }

  static void showReactionDialog({
    required BuildContext context,
    required WidgetRef ref,
    required MessageModel message,
    required int messageIndex,
  }) {
    final chatNotifier = ref.read(chatProvider.notifier);
    HapticFeedback.mediumImpact();

    Navigator.of(context).push(
      HeroDialogRoute(
        builder: (context) {
          return ReactionsDialogWidget(
            id: message.id,
            menuItems: message.isMe ? DefaultData.myMessageMenuItems : DefaultData.menuItems,
            messageWidget: MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: chatNotifier.isSameSender(
                messageIndex,
                groupId: message.groupId,
              ),
              isSameSenderAsNext: chatNotifier.isNextSameSender(
                messageIndex,
                groupId: message.groupId,
              ),
            ),
            onReactionTap: (reaction) {
              if (reaction == '⋯') {
                showEmojiBottomSheet(
                  context: context,
                  ref: ref,
                  message: message,
                );
              } else {
                chatNotifier.updateMessageReaction(message: message, reaction: reaction);
              }
            },
            onContextMenuTap: (menuItem) {
              if (menuItem.label == 'Reply') {
                chatNotifier.handleReply(message);
              } else if (menuItem.label == 'Copy') {
                Clipboard.setData(ClipboardData(text: message.content ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Message copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (menuItem.label == 'Delete') {
                chatNotifier.deleteMessage(
                  groupId: message.groupId ?? '',
                  messageId: message.id,
                  messageKind: message.kind,
                  messagePubkey: message.sender.publicKey,
                );
              }
            },
            widgetAlignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
          );
        },
      ),
    );
  }
}
