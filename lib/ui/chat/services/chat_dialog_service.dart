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

class ChatDialogService {
  static void showEmojiBottomSheet({
    required BuildContext context,
    required WidgetRef ref,
    required MessageModel message,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
            config: const Config(
              bottomActionBarConfig: BottomActionBarConfig(enabled: false),
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
              } else if (menuItem.label == 'Edit') {
                chatNotifier.handleEdit(message);
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
