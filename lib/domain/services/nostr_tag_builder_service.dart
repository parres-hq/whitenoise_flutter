import 'package:whitenoise/src/rust/api/messages.dart';
import 'package:whitenoise/src/rust/api/utils.dart' as utils;

class NostrTagBuilderService {
  final Future<Tag> Function({required List<String> vec}) _tagFromVecFn;

  NostrTagBuilderService({
    Future<Tag> Function({required List<String> vec})? tagFromVecFn,
  }) : _tagFromVecFn = tagFromVecFn ?? utils.tagFromVec;

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
      await _tagFromVecFn(vec: ['p', messagePubkey]),
      await _tagFromVecFn(vec: ['k', messageKind.toString()]),
    ];
  }
}
