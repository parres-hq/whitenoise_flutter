import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/services/nostr_tag_builder_service.dart';

import '../../shared/mocks/mock_tag_test_helpers.dart';

void main() {
  group('NostrTagBuilderService', () {
    group('buildReactionTags', () {
      test('NIP-25: MUST have e tag with event id being reacted to', () async {
        final capturedTags = <List<String>>[];
        final tagBuilder = NostrTagBuilderService(
          tagFromVecFn: mockTagFromVec(capturedTags),
        );
        await tagBuilder.buildReactionTags(
          messageId: 'test-message-id',
          messagePubkey: 'test-pubkey',
          messageKind: 9,
        );
        final eTag = capturedTags.firstWhere((tag) => tag[0] == 'e');
        expect(eTag[1], 'test-message-id');
      });

      test('NIP-25: SHOULD have p tag with pubkey of event being reacted to', () async {
        final capturedTags = <List<String>>[];
        final tagBuilder = NostrTagBuilderService(
          tagFromVecFn: mockTagFromVec(capturedTags),
        );
        await tagBuilder.buildReactionTags(
          messageId: 'test-message-id',
          messagePubkey: 'test-pubkey',
          messageKind: 9,
        );
        final pTag = capturedTags.firstWhere((tag) => tag[0] == 'p');
        expect(pTag[1], 'test-pubkey');
        expect(pTag[2], '');
      });

      test('NIP-25: SHOULD have k tag with stringified kind number of reacted event', () async {
        final capturedTags = <List<String>>[];
        final tagBuilder = NostrTagBuilderService(
          tagFromVecFn: mockTagFromVec(capturedTags),
        );

        await tagBuilder.buildReactionTags(
          messageId: 'test-message-id',
          messagePubkey: 'test-pubkey',
          messageKind: 9,
        );

        final kTag = capturedTags.firstWhere((tag) => tag[0] == 'k');
        expect(kTag[1], '9');
      });

      test('handles different message kinds correctly', () async {
        final capturedTags = <List<String>>[];
        final tagBuilder = NostrTagBuilderService(
          tagFromVecFn: mockTagFromVec(capturedTags),
        );
        await tagBuilder.buildReactionTags(
          messageId: 'id',
          messagePubkey: 'pubkey',
          messageKind: 1,
        );
        final kTag = capturedTags.firstWhere((tag) => tag[0] == 'k');
        expect(kTag[1], '1');
      });

      test('handles empty strings', () async {
        final capturedTags = <List<String>>[];
        final tagBuilder = NostrTagBuilderService(
          tagFromVecFn: mockTagFromVec(capturedTags),
        );
        await tagBuilder.buildReactionTags(
          messageId: '',
          messagePubkey: '',
          messageKind: 0,
        );
        expect(capturedTags.length, 3);
        final eTag = capturedTags.firstWhere((tag) => tag[0] == 'e');
        final pTag = capturedTags.firstWhere((tag) => tag[0] == 'p');
        final kTag = capturedTags.firstWhere((tag) => tag[0] == 'k');
        expect(eTag[1], '');
        expect(pTag[1], '');
        expect(kTag[1], '0');
      });
    });

    group('buildReplyTags', () {
      test('creates reply tags with e tag referencing original message', () async {
        final capturedTags = <List<String>>[];
        final tagBuilder = NostrTagBuilderService(
          tagFromVecFn: mockTagFromVec(capturedTags),
        );
        final tags = await tagBuilder.buildReplyTags(
          replyToMessageId: 'original-message-id',
        );
        expect(tags.length, 1);
        expect(capturedTags.length, 1);
        final eTag = capturedTags.firstWhere((tag) => tag[0] == 'e');
        expect(eTag[1], 'original-message-id');
      });

      test('handles empty message id', () async {
        final capturedTags = <List<String>>[];
        final tagBuilder = NostrTagBuilderService(
          tagFromVecFn: mockTagFromVec(capturedTags),
        );
        await tagBuilder.buildReplyTags(
          replyToMessageId: '',
        );
        final eTag = capturedTags.firstWhere((tag) => tag[0] == 'e');
        expect(eTag[1], '');
      });
    });

    group('buildDeletionTags', () {
      test('NIP-09: MUST have e tag with event id being deleted', () async {
        final capturedTags = <List<String>>[];
        final tagBuilder = NostrTagBuilderService(
          tagFromVecFn: mockTagFromVec(capturedTags),
        );
        await tagBuilder.buildDeletionTags(
          messageId: 'message-to-delete',
          messagePubkey: 'author-pubkey',
          messageKind: 9,
        );
        final eTag = capturedTags.firstWhere((tag) => tag[0] == 'e');
        expect(eTag[1], 'message-to-delete');
      });

      test('NIP-09: SHOULD have p tag with author of the event being deleted', () async {
        final capturedTags = <List<String>>[];
        final tagBuilder = NostrTagBuilderService(
          tagFromVecFn: mockTagFromVec(capturedTags),
        );
        await tagBuilder.buildDeletionTags(
          messageId: 'message-to-delete',
          messagePubkey: 'author-pubkey',
          messageKind: 9,
        );
        final pTag = capturedTags.firstWhere((tag) => tag[0] == 'p');
        expect(pTag[1], 'author-pubkey');
      });

      test('NIP-09: SHOULD have k tag with kind of the event being deleted', () async {
        final capturedTags = <List<String>>[];
        final tagBuilder = NostrTagBuilderService(
          tagFromVecFn: mockTagFromVec(capturedTags),
        );
        await tagBuilder.buildDeletionTags(
          messageId: 'message-to-delete',
          messagePubkey: 'author-pubkey',
          messageKind: 9,
        );
        final kTag = capturedTags.firstWhere((tag) => tag[0] == 'k');
        expect(kTag[1], '9');
      });

      test('handles different message kinds', () async {
        final capturedTags = <List<String>>[];
        final tagBuilder = NostrTagBuilderService(
          tagFromVecFn: mockTagFromVec(capturedTags),
        );
        await tagBuilder.buildDeletionTags(
          messageId: 'id',
          messagePubkey: 'pubkey',
          messageKind: 7,
        );
        final kTag = capturedTags.firstWhere((tag) => tag[0] == 'k');
        expect(kTag[1], '7');
      });

      test('handles empty strings', () async {
        final capturedTags = <List<String>>[];
        final tagBuilder = NostrTagBuilderService(
          tagFromVecFn: mockTagFromVec(capturedTags),
        );
        await tagBuilder.buildDeletionTags(
          messageId: '',
          messagePubkey: '',
          messageKind: 0,
        );
        expect(capturedTags.length, 3);
        final eTag = capturedTags.firstWhere((tag) => tag[0] == 'e');
        final pTag = capturedTags.firstWhere((tag) => tag[0] == 'p');
        final kTag = capturedTags.firstWhere((tag) => tag[0] == 'k');
        expect(eTag[1], '');
        expect(pTag[1], '');
        expect(kTag[1], '0');
      });
    });
  });
}
