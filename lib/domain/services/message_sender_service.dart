import 'package:whitenoise/domain/services/nostr_tag_builder_service.dart';
import 'package:whitenoise/src/rust/api/messages.dart';

const int _messageKind = 9;
const int _reactionKind = 7;
const int _deletionKind = 5;

class MessageSenderService {
  final NostrTagBuilderService _tagBuilder;
  final Future<MessageWithTokens> Function({
    required String pubkey,
    required String groupId,
    required String message,
    required int kind,
    List<Tag>? tags,
  })
  _sendMessageToGroupFn;

  MessageSenderService({
    NostrTagBuilderService? tagBuilder,
    Future<MessageWithTokens> Function({
      required String pubkey,
      required String groupId,
      required String message,
      required int kind,
      List<Tag>? tags,
    })?
    sendMessageToGroupFn,
  }) : _tagBuilder = tagBuilder ?? NostrTagBuilderService(),
       _sendMessageToGroupFn = sendMessageToGroupFn ?? sendMessageToGroup;

  Future<MessageWithTokens> sendMessage({
    required String pubkey,
    required String groupId,
    required String content,
    List<Tag>? tags,
  }) async {
    return _sendMessageToGroupFn(
      pubkey: pubkey,
      groupId: groupId,
      message: content,
      kind: _messageKind,
      tags: tags,
    );
  }

  Future<MessageWithTokens> sendReaction({
    required String pubkey,
    required String groupId,
    required String messageId,
    required String messagePubkey,
    required int messageKind,
    required String emoji,
  }) async {
    final tags = await _tagBuilder.buildReactionTags(
      messageId: messageId,
      messagePubkey: messagePubkey,
      messageKind: messageKind,
    );

    return _sendMessageToGroupFn(
      pubkey: pubkey,
      groupId: groupId,
      message: emoji,
      kind: _reactionKind,
      tags: tags,
    );
  }

  Future<MessageWithTokens> sendReply({
    required String pubkey,
    required String groupId,
    required String replyToMessageId,
    required String content,
  }) async {
    final tags = await _tagBuilder.buildReplyTags(
      replyToMessageId: replyToMessageId,
    );

    return _sendMessageToGroupFn(
      pubkey: pubkey,
      groupId: groupId,
      message: content,
      kind: _messageKind,
      tags: tags,
    );
  }

  Future<MessageWithTokens> sendDeletion({
    required String pubkey,
    required String groupId,
    required String messageId,
    required String messagePubkey,
    required int messageKind,
  }) async {
    final tags = await _tagBuilder.buildDeletionTags(
      messageId: messageId,
      messagePubkey: messagePubkey,
      messageKind: messageKind,
    );

    return _sendMessageToGroupFn(
      pubkey: pubkey,
      groupId: groupId,
      message: '',
      kind: _deletionKind,
      tags: tags,
    );
  }
}
