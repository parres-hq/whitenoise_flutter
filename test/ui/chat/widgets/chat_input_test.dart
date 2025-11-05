import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/chat_input_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/states/chat_state.dart';
import 'package:whitenoise/domain/models/media_file_upload.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' show MediaFile;
import 'package:whitenoise/ui/chat/states/chat_input_state.dart';
import 'package:whitenoise/ui/chat/widgets/chat_input.dart';
import 'package:whitenoise/ui/chat/widgets/chat_input_send_button.dart';
import 'package:whitenoise/ui/core/ui/wn_text_form_field.dart';

import '../../../shared/mocks/mock_active_pubkey_notifier.dart';
import '../../../test_helpers.dart';

class MockChatNotifier extends ChatNotifier {
  @override
  ChatState build() {
    return const ChatState();
  }
}

class MockChatInputNotifier extends ChatInputNotifier {
  final ChatInputState _state;

  MockChatInputNotifier(this._state);

  @override
  ChatInputState build(String groupId) {
    return _state;
  }

  @override
  Future<String?> loadDraft() async => null;

  @override
  void scheduleDraftSave(String text) {}

  @override
  Future<void> saveDraftImmediately(String text) async {}
}

void main() {
  group('ChatInput', () {
    const testGroupId = 'test-group-id';
    const testAccountPubkey = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
    testWidgets('shows text input field', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ChatInput(
            groupId: testGroupId,
            onSend: (content, isEditing) {},
          ),
          overrides: [
            activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier(testAccountPubkey)),
            chatProvider.overrideWith(() => MockChatNotifier()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WnTextFormField), findsOneWidget);
    });

    testWidgets('shows send button', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          ChatInput(
            groupId: testGroupId,
            onSend: (content, isEditing) {},
          ),
          overrides: [
            activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier(testAccountPubkey)),
            chatProvider.overrideWith(() => MockChatNotifier()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChatInputSendButton), findsOneWidget);
    });

    group('when media is uploading', () {
      final stateWithUploadingMedia = const ChatInputState(
        selectedMedia: [
          MediaFileUpload.uploading(filePath: '/path/to/uploading.jpg'),
        ],
      );

      testWidgets('disables send button', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            ChatInput(
              groupId: testGroupId,
              onSend: (content, isEditing) {},
            ),
            overrides: [
              activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier(testAccountPubkey)),
              chatProvider.overrideWith(() => MockChatNotifier()),
              chatInputProvider.overrideWith(() => MockChatInputNotifier(stateWithUploadingMedia)),
            ],
          ),
        );
        await tester.pump();
        await tester.enterText(find.byType(WnTextFormField), 'Test message');
        await tester.pump();

        final sendButton = tester.widget<ChatInputSendButton>(find.byType(ChatInputSendButton));
        expect(sendButton.isDisabled, true);
      });
    });

    group('when media upload failed', () {
      final stateWithFailedMedia = const ChatInputState(
        selectedMedia: [
          MediaFileUpload.failed(filePath: '/path/to/uploading.jpg', error: 'Upload failed'),
        ],
      );

      testWidgets('disables send button', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            ChatInput(
              groupId: testGroupId,
              onSend: (content, isEditing) {},
            ),
            overrides: [
              activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier(testAccountPubkey)),
              chatProvider.overrideWith(() => MockChatNotifier()),
              chatInputProvider.overrideWith(() => MockChatInputNotifier(stateWithFailedMedia)),
            ],
          ),
        );
        await tester.pump();
        await tester.enterText(find.byType(WnTextFormField), 'Test message');
        await tester.pump();

        final sendButton = tester.widget<ChatInputSendButton>(find.byType(ChatInputSendButton));
        expect(sendButton.isDisabled, true);
      });
    });

    group('when media is uploaded', () {
      final testMediaFile = MediaFile(
        id: '123',
        accountPubkey: 'pubkey123',
        originalFileHash: 'file_hash',
        encryptedFileHash: 'test-encrypted-hash',
        mlsGroupId: 'group123',
        filePath: '/path/to/uploaded.jpg',
        mimeType: 'image/jpeg',
        mediaType: 'image',
        blossomUrl: 'https://example.com/image.jpg',
        nostrKey: 'nostr_key',
        createdAt: DateTime(2025, 1, 3),
      );
      final stateWithUploadedMedia = ChatInputState(
        selectedMedia: [
          MediaFileUpload.uploaded(file: testMediaFile, originalFilePath: '/path/to/uploading.jpg'),
        ],
      );

      testWidgets('enables send button', (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestWidget(
            ChatInput(
              groupId: testGroupId,
              onSend: (content, isEditing) {},
            ),
            overrides: [
              activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier(testAccountPubkey)),
              chatProvider.overrideWith(() => MockChatNotifier()),
              chatInputProvider.overrideWith(() => MockChatInputNotifier(stateWithUploadedMedia)),
            ],
          ),
        );
        await tester.pump();
        await tester.enterText(find.byType(WnTextFormField), 'Test message');
        await tester.pump();

        final sendButton = tester.widget<ChatInputSendButton>(find.byType(ChatInputSendButton));
        expect(sendButton.isDisabled, false);
      });
    });
  });
}
