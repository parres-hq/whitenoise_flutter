import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/utils.dart' as utils;

class NostrTagBuilderService {
  final Future<Tag> Function({required List<String> vec}) _tagFromVecFn;

  NostrTagBuilderService({
    Future<Tag> Function({required List<String> vec})? tagFromVecFn,
  }) : _tagFromVecFn = tagFromVecFn ?? utils.tagFromVec;

  // NIP-25 compliant reaction tags
  // According to NIP-25:
  // - MUST have e tag with event id being reacted to
  // - SHOULD have p tag with pubkey of event being reacted to
  // - SHOULD have k tag with stringified kind number of reacted event
  Future<List<Tag>> buildReactionTags({
    required String messageId,
    required String messagePubkey,
    required int messageKind,
  }) async {
    return [
      await _tagFromVecFn(vec: ['e', messageId]),
      await _tagFromVecFn(vec: ['p', messagePubkey, '']),
      await _tagFromVecFn(vec: ['k', messageKind.toString()]),
    ];
  }

  Future<List<Tag>> buildReplyTags({
    required String replyToMessageId,
  }) async {
    return [
      await _tagFromVecFn(vec: ['e', replyToMessageId]),
    ];
  }

  Future<List<Tag>> buildDeletionTags({
    required String messageId,
    required String messagePubkey,
    required int messageKind,
  }) async {
    return [
      await _tagFromVecFn(vec: ['e', messageId]),
      await _tagFromVecFn(vec: ['p', messagePubkey]), // Author of the message being deleted
      await _tagFromVecFn(vec: ['k', messageKind.toString()]), // Kind of the message being deleted
    ];
  }
}
