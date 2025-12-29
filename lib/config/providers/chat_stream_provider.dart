import 'dart:async';

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

  Map<String, ChatMessage> _messageMap = {};
  List<MessageModel> _optimisticMessages = [];
  StreamController<List<MessageModel>>? _controller;
  StreamSubscription<MessageStreamItem>? _rustStreamSubscription;

  ChatStreamNotifier({
    GroupMessageSubscriber subscriber = subscribeToGroupMessages,
  }) : _subscriber = subscriber;

  @override
  Stream<List<MessageModel>> build(String groupId) {
    final activePubkey = ref.watch(activePubkeyProvider);

    _controller?.close();
    _rustStreamSubscription?.cancel();

    _controller = StreamController<List<MessageModel>>();

    _messageMap = {};
    _optimisticMessages = [];

    if (activePubkey == null || activePubkey.isEmpty) {
      _controller?.add([]);
      return _controller?.stream ?? const Stream<List<MessageModel>>.empty();
    }

    _subscribeToRustStream(groupId, activePubkey);

    ref.onDispose(() {
      _logger.info('ChatStreamNotifier: Disposing stream');
      _rustStreamSubscription?.cancel();
      _controller?.close();
    });

    return _controller?.stream ?? const Stream<List<MessageModel>>.empty();
  }

  void _subscribeToRustStream(String groupId, String activePubkey) {
    try {
      _logger.info('ChatStreamNotifier: Requesting stream');
      final stream = _subscriber(groupId: groupId);

      _rustStreamSubscription = stream.listen(
        (item) async {
          item.when(
            initialSnapshot: (messages) {
              _messageMap = {for (var message in messages) message.id: message};
            },
            update: (update) {
              _messageMap[update.message.id] = update.message;
            },
          );

          await _emitMergedState(groupId, activePubkey);
        },
        onError: (error) {
          _logger.severe('ChatStreamNotifier: Error in Rust stream', error);
          if (_messageMap.isEmpty &&
              _optimisticMessages.isEmpty &&
              _controller?.isClosed == false) {
            _controller?.add([]);
          }
        },
      );
    } catch (e) {
      _logger.severe('ChatStreamNotifier: Error building stream for group', e);
      if (_controller?.isClosed == false) {
        _controller?.add([]);
      }
    }
  }

  void addOptimisticMessage(MessageModel message) {
    if (_optimisticMessages.any((m) => m.id == message.id)) {
      return;
    }

    _optimisticMessages.add(message);
    final groupId = arg;
    final activePubkey = ref.read(activePubkeyProvider);

    if (activePubkey != null && activePubkey.isNotEmpty) {
      _emitMergedState(groupId, activePubkey);
    }
  }

  void updateOptimisticReaction(MessageModel optimisticReactionMessage) {
    final activePubkey = ref.read(activePubkeyProvider);

    if (activePubkey != null && activePubkey.isNotEmpty) {
      _optimisticMessages.removeWhere((m) => m.id == optimisticReactionMessage.id);
      _optimisticMessages.add(optimisticReactionMessage);

      final groupId = arg;
      _emitMergedState(groupId, activePubkey);
    }
  }

  void removeOptimisticMessage(String messageId) {
    _optimisticMessages.removeWhere((m) => m.id == messageId);

    final groupId = arg;
    final activePubkey = ref.read(activePubkeyProvider);

    if (activePubkey != null && activePubkey.isNotEmpty) {
      _emitMergedState(groupId, activePubkey);
    }
  }

  Future<void> _emitMergedState(String groupId, String activePubkey) async {
    if (_controller == null || _controller!.isClosed) return;

    _optimisticMessages.removeWhere(
      (optimistic) => _messageMap.containsKey(optimistic.id),
    );

    final sortedMessages =
        _messageMap.values.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final groupMembers =
        ref.read(groupsProvider.select((groupState) => groupState.groupMembers?[groupId])) ?? [];

    final usersMap = {
      for (var user in groupMembers) PubkeyFormatter(pubkey: user.publicKey).toHex() ?? '': user,
    };

    final convertedStreamMessages = await MessageConverter.fromChatMessageList(
      sortedMessages,
      currentUserPublicKey: activePubkey,
      groupId: groupId,
      usersMap: usersMap,
    );

    final optimisticIds = _optimisticMessages.map((m) => m.id).toSet();

    final effectiveStreamMessages = convertedStreamMessages.where(
      (m) => !optimisticIds.contains(m.id),
    );

    final mergedMessages = [...effectiveStreamMessages, ..._optimisticMessages];
    mergedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    if (!_controller!.isClosed) {
      _controller!.add(mergedMessages);
    }
  }
}

final chatStreamProvider = StreamNotifierProvider.autoDispose
    .family<ChatStreamNotifier, List<MessageModel>, String>(
      ChatStreamNotifier.new,
    );
