import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/ui/chat/widgets/message_media_tile.dart';
import 'package:whitenoise/ui/chat/widgets/message_reply_box.dart';

import '../../../test_helpers.dart';

void main() {
  group('MessageReplyBox', () {
    final testUser = User(
      id: 'test-id',
      publicKey: 'test-pubkey',
      displayName: 'Test User',
      nip05: '',
    );

    MediaFile createTestMediaFile({required String id}) {
      return MediaFile(
        id: id,
        mlsGroupId: 'group-id',
        accountPubkey: 'pubkey',
        filePath: '/test/path/$id.jpg',
        originalFileHash: 'hash-$id',
        encryptedFileHash: 'encrypted-hash-$id',
        mimeType: 'image/jpeg',
        mediaType: 'image',
        blossomUrl: 'https://example.com/$id.jpg',
        nostrKey: 'key-$id',
        fileMetadata: const FileMetadata(),
        createdAt: DateTime.now(),
      );
    }

    group('without media attachments', () {
      late MessageModel messageWithoutMedia;

      setUp(() {
        messageWithoutMedia = MessageModel(
          id: 'msg-1',
          content: 'Text only message',
          type: MessageType.text,
          createdAt: DateTime.now(),
          sender: testUser,
          isMe: false,
          mediaAttachments: [],
        );
      });

      testWidgets('shows user name', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MessageReplyBox(
              replyingTo: messageWithoutMedia,
              onTap: () {},
            ),
          ),
        );

        expect(find.text('Test User'), findsOneWidget);
      });

      testWidgets('shows content', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MessageReplyBox(
              replyingTo: messageWithoutMedia,
              onTap: () {},
            ),
          ),
        );

        expect(find.text('Text only message'), findsOneWidget);
      });

      testWidgets('does not show media tile', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MessageReplyBox(
              replyingTo: messageWithoutMedia,
              onTap: () {},
            ),
          ),
        );

        expect(find.byType(MessageMediaTile), findsNothing);
      });
    });

    group('with one media attachment', () {
      late MessageModel messageWithOneMedia;
      late MediaFile singleMedia;

      setUp(() {
        singleMedia = createTestMediaFile(id: 'single');
        messageWithOneMedia = MessageModel(
          id: 'msg-2',
          content: 'Message with one image',
          type: MessageType.image,
          createdAt: DateTime.now(),
          sender: testUser,
          isMe: false,
          mediaAttachments: [singleMedia],
        );
      });

      testWidgets('shows user name', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MessageReplyBox(
              replyingTo: messageWithOneMedia,
              onTap: () {},
            ),
          ),
        );

        expect(find.text('Test User'), findsOneWidget);
      });

      testWidgets('shows content', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MessageReplyBox(
              replyingTo: messageWithOneMedia,
              onTap: () {},
            ),
          ),
        );

        expect(find.text('Message with one image'), findsOneWidget);
      });

      testWidgets('shows one media tile', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MessageReplyBox(
              replyingTo: messageWithOneMedia,
              onTap: () {},
            ),
          ),
        );

        expect(find.byType(MessageMediaTile), findsOneWidget);
      });
    });

    group('with multiple media attachments', () {
      late MessageModel messageWithMultipleMedia;
      late MediaFile firstMedia;
      late MediaFile secondMedia;

      setUp(() {
        firstMedia = createTestMediaFile(id: 'first');
        secondMedia = createTestMediaFile(id: 'second');
        messageWithMultipleMedia = MessageModel(
          id: 'msg-3',
          content: 'Message with multiple images',
          type: MessageType.image,
          createdAt: DateTime.now(),
          sender: testUser,
          isMe: false,
          mediaAttachments: [firstMedia, secondMedia],
        );
      });

      testWidgets('shows user name', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MessageReplyBox(
              replyingTo: messageWithMultipleMedia,
              onTap: () {},
            ),
          ),
        );

        expect(find.text('Test User'), findsOneWidget);
      });

      testWidgets('shows content', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MessageReplyBox(
              replyingTo: messageWithMultipleMedia,
              onTap: () {},
            ),
          ),
        );

        expect(find.text('Message with multiple images'), findsOneWidget);
      });

      testWidgets('shows exactly one media tile', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MessageReplyBox(
              replyingTo: messageWithMultipleMedia,
              onTap: () {},
            ),
          ),
        );

        expect(find.byType(MessageMediaTile), findsOneWidget);
      });

      testWidgets('shows the first media attachment', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MessageReplyBox(
              replyingTo: messageWithMultipleMedia,
              onTap: () {},
            ),
          ),
        );

        final mediaTile = tester.widget<MessageMediaTile>(
          find.byType(MessageMediaTile),
        );
        expect(mediaTile.mediaFile.id, firstMedia.id);
      });
    });
  });
}
