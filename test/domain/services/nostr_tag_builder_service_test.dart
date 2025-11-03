import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/services/nostr_tag_builder_service.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';

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

    group('buildMediaTags', () {
      late NostrTagBuilderService tagBuilder;
      late List<List<String>> tags;

      setUp(() {
        tags = <List<String>>[];
        tagBuilder = NostrTagBuilderService(
          tagFromVecFn: mockTagFromVec(tags),
        );
      });
      group('when media files are empty', () {
        test('returns empty list', () async {
          await tagBuilder.buildMediaTags(mediaFiles: []);
          expect(tags.length, 0);
        });
      });

      group('with single media file', () {
        group('with blurhash and dimensions', () {
          final mediaFile = MediaFile(
            id: 'test-id',
            mlsGroupId: 'test-group',
            accountPubkey: 'test-pubkey',
            filePath: '/path/to/file.jpg',
            fileHash: 'abc123hash',
            mimeType: 'image/jpeg',
            mediaType: 'image',
            blossomUrl: 'https://example.com/file.jpg',
            nostrKey: 'test-key',
            fileMetadata: const FileMetadata(
              blurhash: 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
              dimensions: '1920x1080',
              originalFilename: 'test.jpg',
            ),
            createdAt: DateTime(2024, 1, 2),
          );

          setUp(() async {
            await tagBuilder.buildMediaTags(mediaFiles: [mediaFile]);
          });

          test('returns one tag', () async {
            expect(tags.length, 1);
          });

          test('returns one imeta tag', () async {
            final imetaTag = tags[0];
            expect(imetaTag[0], 'imeta');
          });

          test('returns expected url', () async {
            final imetaTag = tags[0];
            expect(imetaTag[1], 'url https://example.com/file.jpg');
          });

          test('returns expected mime type', () async {
            final imetaTag = tags[0];
            expect(imetaTag[2], 'm image/jpeg');
          });

          test('returns expected hash', () async {
            final imetaTag = tags[0];
            expect(imetaTag[3], 'x abc123hash');
          });

          test('returns expected blurhash', () async {
            final imetaTag = tags[0];
            expect(imetaTag[4], 'blurhash LKO2?U%2Tw=w]~RBVZRi};RPxuwH');
          });

          test('returns expected dimensions', () async {
            final imetaTag = tags[0];
            expect(imetaTag[5], 'dim 1920x1080');
          });
        });

        group('without blurhash', () {
          final mediaFile = MediaFile(
            id: 'test-id',
            mlsGroupId: 'test-group',
            accountPubkey: 'test-pubkey',
            filePath: '/path/to/file.jpg',
            fileHash: 'abc123hash',
            mimeType: 'image/jpeg',
            mediaType: 'image',
            blossomUrl: 'https://example.com/file.jpg',
            nostrKey: 'test-key',
            fileMetadata: const FileMetadata(
              dimensions: '1920x1080',
            ),
            createdAt: DateTime(2024, 1, 2),
          );

          setUp(() async {
            await tagBuilder.buildMediaTags(mediaFiles: [mediaFile]);
          });

          test('returns tag with expected values', () async {
            final imetaTag = tags[0];
            expect(
              imetaTag,
              equals([
                'imeta',
                'url https://example.com/file.jpg',
                'm image/jpeg',
                'x abc123hash',
                'dim 1920x1080',
              ]),
            );
          });
        });

        group('without dimensions', () {
          final mediaFile = MediaFile(
            id: 'test-id',
            mlsGroupId: 'test-group',
            accountPubkey: 'test-pubkey',
            filePath: '/path/to/file.jpg',
            fileHash: 'abc123hash',
            mimeType: 'image/jpeg',
            mediaType: 'image',
            blossomUrl: 'https://example.com/file.jpg',
            nostrKey: 'test-key',
            fileMetadata: const FileMetadata(
              blurhash: 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
            ),
            createdAt: DateTime(2024, 1, 2),
          );

          setUp(() async {
            await tagBuilder.buildMediaTags(mediaFiles: [mediaFile]);
          });

          test('returns tag with expected values', () async {
            final imetaTag = tags[0];
            expect(
              imetaTag,
              equals([
                'imeta',
                'url https://example.com/file.jpg',
                'm image/jpeg',
                'x abc123hash',
                'blurhash LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
              ]),
            );
          });
        });

        group('without file metadata', () {
          final mediaFile = MediaFile(
            id: 'test-id',
            mlsGroupId: 'test-group',
            accountPubkey: 'test-pubkey',
            filePath: '/path/to/file.jpg',
            fileHash: 'abc123hash',
            mimeType: 'image/jpeg',
            mediaType: 'image',
            blossomUrl: 'https://example.com/file.jpg',
            nostrKey: 'test-key',
            createdAt: DateTime(2024, 1, 4),
          );

          setUp(() async {
            await tagBuilder.buildMediaTags(mediaFiles: [mediaFile]);
          });

          test('returns tag with expected values', () async {
            final imetaTag = tags[0];
            expect(
              imetaTag,
              equals([
                'imeta',
                'url https://example.com/file.jpg',
                'm image/jpeg',
                'x abc123hash',
              ]),
            );
          });
        });
      });

      group('with multiple media files', () {
        final mediaFile1 = MediaFile(
          id: 'test-id-1',
          mlsGroupId: 'test-group-1',
          accountPubkey: 'test-pubkey1',
          filePath: '/path/to/file1.jpg',
          fileHash: 'abc123hash',
          mimeType: 'image/jpeg',
          mediaType: 'image',
          blossomUrl: 'https://example.com/file1.jpg',
          nostrKey: 'test-key',
          fileMetadata: const FileMetadata(
            blurhash: 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
            dimensions: '1920x1080',
            originalFilename: 'test.jpg',
          ),
          createdAt: DateTime(2024, 1, 2),
        );

        final mediaFile2 = MediaFile(
          id: 'test-id-2',
          mlsGroupId: 'test-group-2',
          accountPubkey: 'test-pubkey2',
          filePath: '/path/to/file2.jpg',
          fileHash: 'def5678hash',
          mimeType: 'image/jpeg',
          mediaType: 'image',
          blossomUrl: 'https://example.com/file2.jpg',
          nostrKey: 'test-key-2',
          createdAt: DateTime(2024, 1, 5),
        );

        setUp(() async {
          await tagBuilder.buildMediaTags(mediaFiles: [mediaFile1, mediaFile2]);
        });

        test('returns expected number of tags', () async {
          expect(tags.length, 2);
        });

        test('returns first tag with expected values', () async {
          final imetaTag = tags[0];
          expect(
            imetaTag,
            equals([
              'imeta',
              'url https://example.com/file1.jpg',
              'm image/jpeg',
              'x abc123hash',
              'blurhash LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
              'dim 1920x1080',
            ]),
          );
        });

        test('returns second tag with expected values', () async {
          final imetaTag = tags[1];
          expect(
            imetaTag,
            equals([
              'imeta',
              'url https://example.com/file2.jpg',
              'm image/jpeg',
              'x def5678hash',
            ]),
          );
        });
      });
    });
  });
}
