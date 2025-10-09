import 'package:whitenoise/domain/models/message_model.dart';

class MessageMergerService {
  static List<MessageModel> merge({
    required List<MessageModel> stateMessages,
    required List<MessageModel> dbMessages,
  }) {
    final optimisticSendingMessages = _getOptimisticSendingMessages(
      dbMessages: dbMessages,
      stateMessages: stateMessages,
    );
    return [...dbMessages, ...optimisticSendingMessages];
  }

  static List<MessageModel> _getOptimisticSendingMessages({
    required List<MessageModel> stateMessages,
    required List<MessageModel> dbMessages,
  }) {
    final stateSendingMessages =
        stateMessages.where((msg) => msg.status == MessageStatus.sending).toList();

    if (stateSendingMessages.isEmpty) {
      return [];
    }

    if (dbMessages.isEmpty) {
      return stateSendingMessages;
    }

    final messagesToPreserve = <MessageModel>[];
    final sinceTime = DateTime.now().subtract(const Duration(minutes: 1));
    final dbMessagesToCheck = _getMessagesToCheck(
      messages: dbMessages,
      sinceTime: sinceTime,
    );

    final stateSendingMessagesToCheck = _getStateSendingMessagesToCheck(
      stateMessages: stateMessages,
      sinceTime: sinceTime,
    );
    for (final sendingMsg in stateSendingMessagesToCheck) {
      final hasMatchingNewMessage = dbMessagesToCheck.any(
        (msg) =>
            msg.sender.publicKey == sendingMsg.sender.publicKey &&
            msg.kind == sendingMsg.kind &&
            _hasSameContent(sendingMsg, msg),
      );

      if (!hasMatchingNewMessage) {
        messagesToPreserve.add(sendingMsg);
      }
    }

    return messagesToPreserve;
  }

  static List<MessageModel> _getStateSendingMessagesToCheck({
    required List<MessageModel> stateMessages,
    required DateTime sinceTime,
  }) {
    final stateMessagesToCheck = _getMessagesToCheck(
      messages: stateMessages,
      sinceTime: sinceTime,
    );
    final stateSendingMessagesToCheck =
        stateMessagesToCheck.where((msg) => msg.status == MessageStatus.sending).toList();
    return stateSendingMessagesToCheck;
  }

  static List<MessageModel> _getMessagesToCheck({
    required List<MessageModel> messages,
    required DateTime sinceTime,
  }) {
    final int maxRecentMessagesToScan = 10;
    final dbMessagesSublist =
        messages.length <= maxRecentMessagesToScan
            ? messages
            : messages.sublist(messages.length - maxRecentMessagesToScan);
    final recentNewMessagesSublist =
        dbMessagesSublist.where((msg) {
          return msg.createdAt.isAfter(sinceTime);
        }).toList();
    return recentNewMessagesSublist;
  }

  static bool _hasSameContent(MessageModel message1, MessageModel message2) {
    final content1 = message1.content?.trim() ?? '';
    final content2 = message2.content?.trim() ?? '';
    return content1 == content2;
  }
}
