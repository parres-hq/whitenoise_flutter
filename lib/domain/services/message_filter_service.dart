import 'package:whitenoise/domain/models/message_model.dart';

class MessageFilterService {
  static List<MessageModel> getRecentSendingMessages({
    required List<MessageModel> currentMessages,
    required List<MessageModel> newMessages,
    Duration preservationDuration = const Duration(minutes: 1),
  }) {
    final now = DateTime.now();
    final cutoffTime = now.subtract(preservationDuration);

    final sendingMessages =
        currentMessages.where((msg) => msg.status == MessageStatus.sending).toList();

    if (sendingMessages.isEmpty || newMessages.isEmpty) {
      return [];
    }

    final lastServerMessage = newMessages.last;

    final messagesToPreserve = <MessageModel>[];

    for (final sendingMsg in sendingMessages) {
      final isRecent = sendingMsg.createdAt.isAfter(cutoffTime);
      final hasDifferentContent = _hasMessageContentChanged(
        sendingMsg,
        lastServerMessage,
      );

      if (isRecent && hasDifferentContent) {
        messagesToPreserve.add(sendingMsg);
      }
    }

    return messagesToPreserve;
  }

  static bool _hasMessageContentChanged(MessageModel message1, MessageModel message2) {
    final content1 = message1.content?.trim() ?? '';
    final content2 = message2.content?.trim() ?? '';
    return content1 != content2;
  }
}
