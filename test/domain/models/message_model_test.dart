import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';

void main() {
  group('MessageModel', () {
    final testUser = User(
      id: 'user123',
      displayName: 'Test User',
      nip05: 'test@example.com',
      publicKey: 'pubkey123',
    );

    final testMediaFile1 = MediaFile(
      id: 'media1',
      mlsGroupId: 'group123',
      accountPubkey: 'pubkey123',
      filePath: '/path/to/image1.jpg',
      originalFileHash: 'hash1',
      encryptedFileHash: 'test-encrypted-hash1',
      mimeType: 'image/jpeg',
      mediaType: 'image',
      blossomUrl: 'https://example.com/image1.jpg',
      nostrKey: 'nostr_key1',
      fileMetadata: const FileMetadata(
        originalFilename: 'image1.jpg',
        dimensions: '1920x1080',
        blurhash: 'LKO2?U%2Tw=w]~RBVZRi};RPxuwH',
      ),
      createdAt: DateTime(2024),
    );

    final testMediaFile2 = MediaFile(
      id: 'media2',
      mlsGroupId: 'group123',
      accountPubkey: 'pubkey123',
      filePath: '/path/to/image2.jpg',
      originalFileHash: 'hash2',
      encryptedFileHash: 'test-encrypted-hash2',
      mimeType: 'image/jpeg',
      mediaType: 'image',
      blossomUrl: 'https://example.com/image2.jpg',
      nostrKey: 'nostr_key2',
      fileMetadata: const FileMetadata(
        originalFilename: 'image2.jpg',
        dimensions: '1080x1920',
        blurhash: 'LKO2?U%2Tw=w]~RBVZRi};RPxuwI',
      ),
      createdAt: DateTime(2024, 1, 2),
    );

    group('constructor', () {
      final message = MessageModel(
        id: 'msg123',
        content: 'Test message',
        type: MessageType.text,
        createdAt: DateTime(2024, 1, 2),
        sender: testUser,
        isMe: true,
      );

      test('kind is 9 by default', () {
        expect(message.kind, 9);
      });
      test('media attachments are empty by default', () {
        expect(message.mediaAttachments, isEmpty);
      });

      test('status is sent by default', () {
        expect(message.status, MessageStatus.sent);
      });

      test('id matches provided id', () {
        expect(message.id, 'msg123');
      });

      test('content matches provided content', () {
        expect(message.content, 'Test message');
      });

      test('type matches provided type', () {
        expect(message.type, MessageType.text);
      });

      test('createdAt matches provided createdAt', () {
        expect(message.createdAt, DateTime(2024, 1, 2));
      });

      test('sender matches provided sender', () {
        expect(message.sender, testUser);
      });

      test('isMe matches provided isMe', () {
        expect(message.isMe, true);
      });

      group('with other params', () {
        final otherMessage = MessageModel(
          id: 'msg123',
          content: 'Test message with multiple media',
          type: MessageType.image,
          createdAt: DateTime.now(),
          sender: testUser,
          status: MessageStatus.sending,
          isMe: true,
          kind: 10,
          mediaAttachments: [testMediaFile1, testMediaFile2],
        );
        test('returns status provided', () {
          expect(otherMessage.status, MessageStatus.sending);
        });

        test('returns kind provided', () {
          expect(otherMessage.kind, 10);
        });

        test('returns expected amount of media attachments', () {
          expect(otherMessage.mediaAttachments.length, 2);
        });

        test('returns media attachments in same order as provided', () {
          expect(otherMessage.mediaAttachments[0], testMediaFile1);
          expect(otherMessage.mediaAttachments[1], testMediaFile2);
        });
      });
    });

    group('copyWith', () {
      late MessageModel originalMessage;
      late MessageModel copiedMessage;

      setUp(() {
        originalMessage = MessageModel(
          id: 'msg123',
          content: 'Original message',
          type: MessageType.text,
          createdAt: DateTime(2024),
          sender: testUser,
          isMe: true,
          groupId: 'group123',
          status: MessageStatus.sending,
          mediaAttachments: [testMediaFile1],
        );
      });
      group('with media attachments', () {
        setUp(() {
          final newMediaAttachments = [testMediaFile2];
          copiedMessage = originalMessage.copyWith(
            mediaAttachments: newMediaAttachments,
          );
        });

        test('updates mediaAttachments', () {
          expect(copiedMessage.mediaAttachments.length, 1);
          expect(copiedMessage.mediaAttachments.first, testMediaFile2);
        });

        test('preservesother fields', () {
          expect(copiedMessage.id, originalMessage.id);
          expect(copiedMessage.content, originalMessage.content);
          expect(copiedMessage.sender, originalMessage.sender);
        });
      });

      group('with empty media attachments', () {
        setUp(() {
          copiedMessage = originalMessage.copyWith(
            mediaAttachments: [],
          );
        });

        test('updates mediaAttachments to empty list', () {
          expect(copiedMessage.mediaAttachments, isEmpty);
        });

        test('preserves other fields', () {
          expect(copiedMessage.id, originalMessage.id);
          expect(copiedMessage.content, originalMessage.content);
          expect(copiedMessage.sender, originalMessage.sender);
        });
      });
    });
  });
}
