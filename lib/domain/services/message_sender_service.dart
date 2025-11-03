import 'package:whitenoise/domain/services/nostr_tag_builder_service.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
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
    required List<MediaFile> mediaFiles,
  }) async {
    final tags = await _tagBuilder.buildMediaTags(
      mediaFiles: mediaFiles,
    );
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
    required List<MediaFile> mediaFiles,
  }) async {
    final replyTags = await _tagBuilder.buildReplyTags(
      replyToMessageId: replyToMessageId,
    );
    final mediaTags = await _tagBuilder.buildMediaTags(
      mediaFiles: mediaFiles,
    );
    final tags = [...replyTags, ...mediaTags];

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
