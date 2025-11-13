import 'package:whitenoise/domain/models/message_model.dart';

class MessageMergerService {
  static List<MessageModel> merge({
    required List<MessageModel> stateMessages,
    required List<MessageModel> dbMessages,
  }) {
    final sendingMessages =
        stateMessages.where((msg) => msg.status == MessageStatus.sending).toList();

    if (sendingMessages.isEmpty) {
      return dbMessages;
    }

    final dbMessageIds = dbMessages.map((m) => m.id).toSet();
    final stillSending = sendingMessages.where((msg) => !dbMessageIds.contains(msg.id)).toList();
    final cutoffTime = DateTime.now().subtract(const Duration(minutes: 2));
    final recentStillSending =
        stillSending.map((msg) {
          if (msg.createdAt.isBefore(cutoffTime)) {
            return msg.copyWith(status: MessageStatus.failed);
          }
          return msg;
        }).toList();

    return [...dbMessages, ...recentStillSending];
  }
}
