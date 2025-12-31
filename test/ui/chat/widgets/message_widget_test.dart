import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/states/chat_search_state.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/src/rust/api/media_files.dart';
import 'package:whitenoise/ui/chat/widgets/chat_bubble/bubble.dart';
import 'package:whitenoise/ui/chat/widgets/message_media_grid.dart';
import 'package:whitenoise/ui/chat/widgets/message_reply_box.dart';
import 'package:whitenoise/ui/chat/widgets/message_widget.dart';
import 'package:whitenoise/ui/core/ui/wn_avatar.dart';
import 'package:whitenoise/ui/core/ui/wn_image.dart';

import '../../../test_helpers.dart';

void main() {
  group('MessageWidget', () {
    final testUser = User(
      id: 'test-user-id',
      publicKey: 'test-pubkey',
      displayName: 'Test User',
      nip05: 'test@example.com',
    );

    final testUserMe = User(
      id: 'me-user-id',
      publicKey: 'me-pubkey',
      displayName: 'Me',
      nip05: 'me@example.com',
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

    MessageModel createTestMessage({
      required String id,
      String? content,
      required User sender,
      required bool isMe,
      List<MediaFile> mediaAttachments = const [],
      MessageModel? replyTo,
      List<Reaction> reactions = const [],
      MessageStatus status = MessageStatus.sent,
    }) {
      final MessageType messageType;
      if (content != null) {
        messageType = MessageType.text;
      } else if (mediaAttachments.isNotEmpty) {
        messageType = MessageType.image;
      } else {
        messageType = MessageType.text;
      }
      return MessageModel(
        id: id,
        content: content,
        type: messageType,
        createdAt: DateTime.now(),
        sender: sender,
        isMe: isMe,
        mediaAttachments: mediaAttachments,
        replyTo: replyTo,
        reactions: reactions,
        status: status,
      );
    }

    group('basic rendering', () {
      testWidgets('renders message widget', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Test message',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.byType(MessageWidget), findsOneWidget);
      });

      testWidgets('displays message content', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Hello world',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.text('Hello world'), findsOneWidget);
      });

      testWidgets('renders chat bubble', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Test',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.byType(ChatMessageBubble), findsOneWidget);
      });
    });

    group('message alignment', () {
      testWidgets('aligns to right when isMe is true', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'My message',
          sender: testUserMe,
          isMe: true,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        final row = tester.widget<Row>(find.byType(Row).first);
        expect(row.mainAxisAlignment, MainAxisAlignment.end);
      });

      testWidgets('aligns to left when isMe is false', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Other message',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        final row = tester.widget<Row>(find.byType(Row).first);
        expect(row.mainAxisAlignment, MainAxisAlignment.start);
      });
    });

    group('group messages', () {
      late MessageModel groupMessage;

      setUp(() {
        groupMessage = createTestMessage(
          id: 'msg-1',
          content: 'Group message',
          sender: testUser,
          isMe: false,
        );
      });

      testWidgets('shows avatar when isGroupMessage is true and not same sender', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: groupMessage,
              isGroupMessage: true,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.byType(WnAvatar), findsOneWidget);
      });

      testWidgets('hides avatar when same sender as previous', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: groupMessage,
              isGroupMessage: true,
              isSameSenderAsPrevious: true,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.byType(WnAvatar), findsNothing);
      });

      testWidgets('shows sender name in group when not same sender', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: groupMessage,
              isGroupMessage: true,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.text('Test User'), findsOneWidget);
      });

      testWidgets('hides sender name when same sender as previous', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: groupMessage,
              isGroupMessage: true,
              isSameSenderAsPrevious: true,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.text('Test User'), findsNothing);
      });

      testWidgets('does not show avatar for own messages in group', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'My group message',
          sender: testUserMe,
          isMe: true,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: true,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.byType(WnAvatar), findsNothing);
      });
    });

    group('media attachments', () {
      testWidgets('shows media grid when message has media', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        final mediaFile = createTestMediaFile(id: 'media-1');
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Message with media',
          sender: testUser,
          isMe: false,
          mediaAttachments: [mediaFile],
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MessageMediaGrid), findsOneWidget);
        addTearDown(() => tester.binding.setSurfaceSize(null));
      });

      testWidgets('does not show media grid when message has no media', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Text only',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.byType(MessageMediaGrid), findsNothing);
      });

      testWidgets('shows content and media together', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        final mediaFile = createTestMediaFile(id: 'media-1');
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Check this out',
          sender: testUser,
          isMe: false,
          mediaAttachments: [mediaFile],
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Check this out'), findsOneWidget);
        expect(find.byType(MessageMediaGrid), findsOneWidget);
        addTearDown(() => tester.binding.setSurfaceSize(null));
      });

      testWidgets('media grid respects 74% screen width rule', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        final mediaFiles = [
          createTestMediaFile(id: 'media-1'),
          createTestMediaFile(id: 'media-2'),
          createTestMediaFile(id: 'media-3'),
        ];
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Message with multiple media',
          sender: testUser,
          isMe: false,
          mediaAttachments: mediaFiles,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        final intrinsicWidth = find.descendant(
          of: find.byType(MessageWidget),
          matching: find.byType(IntrinsicWidth),
        );

        expect(intrinsicWidth, findsOneWidget);

        final constrainedBoxFinder = find.descendant(
          of: intrinsicWidth,
          matching: find.byType(ConstrainedBox),
        );

        expect(constrainedBoxFinder, findsAtLeastNWidgets(1));

        final constrainedBox = tester.widget<ConstrainedBox>(constrainedBoxFinder.first);

        final screenWidth = 800.0;
        final expectedMaxWidth = screenWidth * 0.74;
        expect(constrainedBox.constraints.maxWidth, closeTo(expectedMaxWidth, 0.1));
        addTearDown(() => tester.binding.setSurfaceSize(null));
      });
    });

    group('reply to message', () {
      testWidgets('shows reply box when message has replyTo', (WidgetTester tester) async {
        final repliedMessage = createTestMessage(
          id: 'msg-replied',
          content: 'Original message',
          sender: testUser,
          isMe: false,
        );

        final message = createTestMessage(
          id: 'msg-1',
          content: 'Reply message',
          sender: testUserMe,
          isMe: true,
          replyTo: repliedMessage,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.byType(MessageReplyBox), findsOneWidget);
      });

      testWidgets('does not show reply box when message has no replyTo', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Regular message',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.byType(MessageReplyBox), findsNothing);
      });
    });

    group('reactions', () {
      testWidgets('shows reactions when message has reactions', (WidgetTester tester) async {
        final reaction1 = Reaction(emoji: '👍', user: testUser);
        final reaction2 = Reaction(emoji: '❤️', user: testUserMe);
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Message with reactions',
          sender: testUser,
          isMe: false,
          reactions: [reaction1, reaction2],
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.text('👍'), findsOneWidget);
        expect(find.text('❤️'), findsOneWidget);
      });

      testWidgets('does not show reactions when message has no reactions', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Message without reactions',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.text('👍'), findsNothing);
      });

      testWidgets('shows reaction count when multiple same emoji', (WidgetTester tester) async {
        final reaction1 = Reaction(emoji: '👍', user: testUser);
        final reaction2 = Reaction(emoji: '👍', user: testUserMe);
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Message',
          sender: testUser,
          isMe: false,
          reactions: [reaction1, reaction2],
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.text('👍'), findsOneWidget);
        expect(find.textContaining(' 2'), findsOneWidget);
      });

      testWidgets('shows ellipsis when more than 3 reactions', (WidgetTester tester) async {
        final reactions = List.generate(
          5,
          (index) => Reaction(
            emoji: index % 2 == 0 ? '👍' : '❤️',
            user: testUser,
          ),
        );
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Message',
          sender: testUser,
          isMe: false,
          reactions: reactions,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.text('...'), findsOneWidget);
      });
    });

    group('message spacing', () {
      testWidgets('has margin when same sender as previous', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Message',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: true,
              isSameSenderAsNext: false,
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MessageWidget),
            matching: find.byType(Container).first,
          ),
        );

        expect(container.margin, isNotNull);
      });

      testWidgets('has margin when different sender', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Message',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MessageWidget),
            matching: find.byType(Container).first,
          ),
        );

        expect(container.margin, isNotNull);
      });

      testWidgets('has margin when message has reactions', (WidgetTester tester) async {
        final reaction = Reaction(emoji: '👍', user: testUser);
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Message',
          sender: testUser,
          isMe: false,
          reactions: [reaction],
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        final container = tester.widget<Container>(
          find.descendant(
            of: find.byType(MessageWidget),
            matching: find.byType(Container).first,
          ),
        );

        expect(container.margin, isNotNull);
      });
    });

    group('callbacks', () {
      testWidgets('calls onTap when tapped', (WidgetTester tester) async {
        var tapped = false;
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Message',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        );

        await tester.tap(find.byType(MessageWidget));
        expect(tapped, isTrue);
      });

      testWidgets('calls onReactionTap when reaction is tapped', (WidgetTester tester) async {
        String? tappedEmoji;
        final reaction = Reaction(emoji: '👍', user: testUser);
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Message',
          sender: testUser,
          isMe: false,
          reactions: [reaction],
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
              onReactionTap: (emoji) {
                tappedEmoji = emoji;
              },
            ),
          ),
        );

        await tester.tap(find.text('👍'));
        expect(tappedEmoji, '👍');
      });

      testWidgets('calls onReplyTap when reply box is tapped', (WidgetTester tester) async {
        String? tappedReplyId;
        final repliedMessage = createTestMessage(
          id: 'msg-replied',
          content: 'Original',
          sender: testUser,
          isMe: false,
        );
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Reply',
          sender: testUserMe,
          isMe: true,
          replyTo: repliedMessage,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
              onReplyTap: (replyId) {
                tappedReplyId = replyId;
              },
            ),
          ),
        );

        await tester.tap(find.byType(MessageReplyBox));
        expect(tappedReplyId, 'msg-replied');
      });
    });

    group('search highlighting', () {
      testWidgets('shows normal text when search is not active', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Test message content',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.text('Test message content'), findsOneWidget);
      });

      testWidgets('highlights search matches when search is active', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Test message content',
          sender: testUser,
          isMe: false,
        );

        final searchMatch = const SearchMatch(
          messageId: 'msg-1',
          messageIndex: 0,
          messageContent: 'Test message content',
          textMatches: [
            TextMatch(start: 0, end: 4, matchedText: 'Test'),
          ],
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
              isSearchActive: true,
              searchMatch: searchMatch,
            ),
          ),
        );

        final richTextFinder = find.descendant(
          of: find.byType(MessageWidget),
          matching: find.byType(RichText),
        );
        expect(richTextFinder, findsAtLeastNWidgets(1));
      });

      testWidgets('shows muted text when search active but no matches', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Test message content',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
              isSearchActive: true,
            ),
          ),
        );

        expect(find.byType(Text), findsWidgets);
      });
    });

    group('message status', () {
      testWidgets('shows status icon for own messages', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'My message',
          sender: testUserMe,
          isMe: true,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.text(message.timeSent), findsOneWidget);
      });

      testWidgets('shows time but not status icon for other messages', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Other message',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        expect(find.text(message.timeSent), findsOneWidget);
        expect(find.byType(WnImage), findsNothing);
      });
    });

    group('bubble tail', () {
      testWidgets('shows tail when not same sender as previous', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Message',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );

        final bubble = tester.widget<ChatMessageBubble>(find.byType(ChatMessageBubble));
        expect(bubble.tail, isTrue);
      });

      testWidgets('hides tail when same sender as previous', (WidgetTester tester) async {
        final message = createTestMessage(
          id: 'msg-1',
          content: 'Message',
          sender: testUser,
          isMe: false,
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: true,
              isSameSenderAsNext: false,
            ),
          ),
        );

        final bubble = tester.widget<ChatMessageBubble>(find.byType(ChatMessageBubble));
        expect(bubble.tail, isFalse);
      });
    });

    group('empty content', () {
      testWidgets('shows only timestamp when message has no content but has media', (WidgetTester tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1200));
        final mediaFile = createTestMediaFile(id: 'media-1');
        final message = createTestMessage(
          id: 'msg-1',
          sender: testUser,
          isMe: false,
          mediaAttachments: [mediaFile],
        );

        await tester.pumpWidget(
          createTestWidget(
            MessageWidget(
              message: message,
              isGroupMessage: false,
              isSameSenderAsPrevious: false,
              isSameSenderAsNext: false,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MessageMediaGrid), findsOneWidget);
        expect(find.text(message.timeSent), findsOneWidget);
        addTearDown(() => tester.binding.setSurfaceSize(null));
      });
    });
  });
}

