import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/group_provider.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/utils/message_converter.dart';
import 'package:whitenoise/utils/pubkey_formatter.dart';

typedef GroupMessageSubscriber =
    Stream<MessageStreamItem> Function({
      required String groupId,
    });

class ChatStreamNotifier extends AutoDisposeFamilyStreamNotifier<List<MessageModel>, String> {
  final _logger = Logger('ChatStreamNotifier');

  final GroupMessageSubscriber _subscriber;

  ChatStreamNotifier({
    GroupMessageSubscriber subscriber = subscribeToGroupMessages,
  }) : _subscriber = subscriber;

  @override
  Stream<List<MessageModel>> build(String groupId) async* {
    final activePubkey = ref.watch(activePubkeyProvider);
    if (activePubkey == null || activePubkey.isEmpty) {
      yield [];
      return;
    }

    Map<String, ChatMessage> messageMap = {};

    try {
      _logger.info('ChatStreamNotifier: Requesting stream for group $groupId');

      final stream = _subscriber(groupId: groupId);

      await for (final item in stream) {
        item.when(
          initialSnapshot: (messages) {
            messageMap = {for (var message in messages) message.id: message};
          },
          update: (update) {
            messageMap[update.message.id] = update.message;
          },
        );

        //maintainin strict chronological order to handle potential
        // out-of-order delivery of real-time updates.
        final sortedMessages =
            messageMap.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        // Watch group members to resolve sender details -replace with get group members from rust later
        final groupMembers =
            ref.watch(groupsProvider.select((groupState) => groupState.groupMembers?[groupId])) ??
            [];

        final usersMap = {
          for (var user in groupMembers)
            // TODO: refactor to always return a hex pubkey in codebase, fomart to npub only in UI
            PubkeyFormatter(pubkey: user.publicKey).toHex() ?? '': user,
        };

        final convertedMessages = await MessageConverter.fromChatMessageList(
          sortedMessages,
          currentUserPublicKey: activePubkey,
          groupId: groupId,
          usersMap: usersMap,
        );

        yield convertedMessages;
      }
    } catch (e) {
      _logger.severe('ChatStreamNotifier: Error building stream for group', e);
      if (messageMap.isEmpty) {
        yield [];
      }
    }
  }
}

final chatStreamProvider = StreamNotifierProvider.autoDispose
    .family<ChatStreamNotifier, List<MessageModel>, String>(
      ChatStreamNotifier.new,
    );
