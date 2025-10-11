import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/utils/localization_extensions.dart';

class MessageUtils {
  // Get display name for a message, handling localization for current user
  static String getDisplayName(MessageModel? replyingTo, MessageModel? editingMessage) {
    if (replyingTo != null) {
      if (replyingTo.isMe) {
        return 'chats.you'.tr();
      }
      return replyingTo.sender.displayName;
    }

    if (editingMessage != null) {
      if (editingMessage.isMe) {
        return 'chats.you'.tr();
      }
      return editingMessage.sender.displayName;
    }

    return 'chats.unknownUser'.tr();
  }
}
