import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/chat_input_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/config/states/chat_state.dart';
import 'package:whitenoise/domain/models/media_file_upload.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart' show User;
import 'package:whitenoise/src/rust/api/media_files.dart' as rust_media_files;
import 'package:whitenoise/src/rust/api/messages.dart' show MessageWithTokens;

import '../../shared/mocks/mock_active_pubkey_notifier.dart';
import '../../shared/mocks/mock_draft_message_service.dart';
import '../../shared/mocks/mock_image_picker_service.dart';

class MockUploadMediaFn {
  final Map<String, rust_media_files.MediaFile> _uploadResults = {};
  final List<String> _failingPaths = [];
  final List<Map<String, String>> _uploadCalls = [];

  void setUploadResult(String filePath, rust_media_files.MediaFile result) {
    _uploadResults[filePath] = result;
  }

  void setUploadFailure(String filePath) {
    _failingPaths.add(filePath);
  }

  List<Map<String, String>> get uploadCalls => _uploadCalls;

  Future<rust_media_files.MediaFile> call({
    required String accountPubkey,
    required String groupId,
    required String filePath,
  }) async {
    _uploadCalls.add({
      'accountPubkey': accountPubkey,
      'groupId': groupId,
      'filePath': filePath,
    });

    if (_failingPaths.contains(filePath)) {
      throw Exception('Upload failed for $filePath');
    }

    final result = _uploadResults[filePath];
    if (result == null) {
      throw Exception('No upload result configured for $filePath');
    }

    return result;
  }

  void reset() {
    _uploadResults.clear();
    _failingPaths.clear();
    _uploadCalls.clear();
  }
}

rust_media_files.MediaFile createMockMediaFile({
  required String id,
  required String groupId,
  required String filePath,
}) {
  return rust_media_files.MediaFile(
    id: id,
    mlsGroupId: groupId,
    accountPubkey: 'test-account-pubkey-hex',
    filePath: filePath,
    originalFileHash: 'test-hash-$id',
    encryptedFileHash: 'test-encrypted-hash-$id',
    mimeType: 'image/jpeg',
    mediaType: 'image',
    blossomUrl: 'https://test.com/media/$id',
    nostrKey: 'test-nostr-key-$id',
    createdAt: DateTime(2025, 1, 3),
  );
}

class MockChatProvider extends ChatNotifier {
  MessageWithTokens? _messageToReturn;
  final List<Map<String, dynamic>> _sendMessageCalls = [];
  final List<Map<String, dynamic>> _sendReplyMessageCalls = [];
  ChatState _currentState = const ChatState();

  void setMessageToReturn(MessageWithTokens? message) {
    _messageToReturn = message;
  }

  void setChatState(ChatState newState) {
    _currentState = newState;
  }

  List<Map<String, dynamic>> get sendMessageCalls => _sendMessageCalls;
  List<Map<String, dynamic>> get sendReplyMessageCalls => _sendReplyMessageCalls;

  @override
  ChatState build() {
    return _currentState;
  }

  @override
  Future<MessageWithTokens?> sendMessage({
    required String groupId,
    required String message,
    required List<rust_media_files.MediaFile> mediaFiles,
    bool isEditing = false,
    void Function()? onMessageSent,
  }) async {
    _sendMessageCalls.add({
      'groupId': groupId,
      'message': message,
      'mediaFiles': mediaFiles,
      'isEditing': isEditing,
    });
    return _messageToReturn;
  }

  @override
  Future<MessageWithTokens?> sendReplyMessage({
    required String groupId,
    required String replyToMessageId,
    required String message,
    void Function()? onMessageSent,
    required List<rust_media_files.MediaFile> mediaFiles,
  }) async {
    _sendReplyMessageCalls.add({
      'groupId': groupId,
      'replyToMessageId': replyToMessageId,
      'message': message,
      'mediaFiles': mediaFiles,
    });
    return _messageToReturn;
  }

  void reset() {
    _sendMessageCalls.clear();
    _sendReplyMessageCalls.clear();
    _messageToReturn = null;
    _currentState = const ChatState();
  }
}

MessageWithTokens createMessageWithTokens({
  required String id,
  required String pubkey,
}) {
  return MessageWithTokens(
    id: id,
    pubkey: pubkey,
    kind: 9,
    createdAt: DateTime(2025, 1, 3),
    content: 'Test message',
    tokens: [],
  );
}

void main() {
  group('ChatInputProvider Tests', () {
    late ProviderContainer container;
    late ChatInputNotifier notifier;
    late MockImagePickerService mockImagePicker;
    late MockDraftMessageService mockDraftMessageService;
    late MockUploadMediaFn mockUploadMedia;
    late MockChatProvider mockChatProvider;
    const testGroupId = 'test-group-id';
    const testAccountPubkey = 'abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890';
    const testDraftSaveDelay = Duration(milliseconds: 5);

    Future<void> waitForUploadsToComplete() async {
      await Future.delayed(Duration.zero); // just yield to let the event loop process
    }

    setUp(() {
      mockImagePicker = MockImagePickerService();
      mockDraftMessageService = MockDraftMessageService();
      mockUploadMedia = MockUploadMediaFn();
      mockChatProvider = MockChatProvider();

      container = ProviderContainer(
        overrides: [
          activePubkeyProvider.overrideWith(() => MockActivePubkeyNotifier(testAccountPubkey)),
          chatProvider.overrideWith(() => mockChatProvider),
          chatInputProvider.overrideWith(
            () => ChatInputNotifier(
              imagePickerService: mockImagePicker,
              draftMessageService: mockDraftMessageService,
              draftSaveDelay: testDraftSaveDelay,
              uploadMediaFn: mockUploadMedia.call,
            ),
          ),
        ],
      );
      notifier = container.read(chatInputProvider(testGroupId).notifier);
    });

    tearDown(() {
      mockUploadMedia.reset();
      mockChatProvider.reset();
      container.dispose();
    });

    group('initial state', () {
      test('is not loading draft', () {
        final testContainer = ProviderContainer();
        final state = testContainer.read(chatInputProvider('test-group-123'));
        expect(state.isLoadingDraft, false);
      });

      test('is not showing media selector', () {
        final testContainer = ProviderContainer();
        final state = testContainer.read(chatInputProvider('test-group-123'));
        expect(state.showMediaSelector, false);
      });

      test('selected media is empty', () {
        final testContainer = ProviderContainer();
        final state = testContainer.read(chatInputProvider('test-group-123'));
        expect(state.selectedMedia, isEmpty);
      });

      test('single line height is null', () {
        final testContainer = ProviderContainer();
        final state = testContainer.read(chatInputProvider('test-group-123'));
        expect(state.singleLineHeight, isNull);
      });

      test('previous editing message content is null', () {
        final testContainer = ProviderContainer();
        final state = testContainer.read(chatInputProvider('test-group-123'));
        expect(state.previousEditingMessageContent, isNull);
      });
    });

    group('toggleMediaSelector', () {
      test('sets showMediaSelector to true', () {
        expect(container.read(chatInputProvider(testGroupId)).showMediaSelector, false);
        notifier.toggleMediaSelector();
        expect(container.read(chatInputProvider(testGroupId)).showMediaSelector, true);
      });

      test('sets showMediaSelector back to false', () {
        expect(container.read(chatInputProvider(testGroupId)).showMediaSelector, false);
        notifier.toggleMediaSelector();
        expect(container.read(chatInputProvider(testGroupId)).showMediaSelector, true);
        notifier.toggleMediaSelector();
        expect(container.read(chatInputProvider(testGroupId)).showMediaSelector, false);
      });
    });

    group('hideMediaSelector', () {
      test('sets showMediaSelector to false', () {
        notifier.toggleMediaSelector();
        expect(container.read(chatInputProvider(testGroupId)).showMediaSelector, true);
        notifier.hideMediaSelector();
        expect(container.read(chatInputProvider(testGroupId)).showMediaSelector, false);
      });
    });

    group('handleImagesSelected', () {
      group('when images are selected', () {
        setUp(() {
          mockImagePicker.imagesToReturn = ['/path/to/image1.jpg', '/path/to/image2.jpg'];
        });

        test('adds expected amount of media file upload items', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia.length, 2);
        });

        test('adds media file uploads in uploading state', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia.length, 2);
          final firstMediaUpload = state.selectedMedia[0];
          final secondMediaUpload = state.selectedMedia[1];
          expect(firstMediaUpload.isUploading, true);
          expect(secondMediaUpload.isUploading, true);
        });

        test('adds media file upload items with expected file paths', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia.length, 2);
          final firstMediaUpload = state.selectedMedia[0];
          final secondMediaUpload = state.selectedMedia[1];
          expect(firstMediaUpload.filePath, '/path/to/image1.jpg');
          expect(secondMediaUpload.filePath, '/path/to/image2.jpg');
        });

        test('sets showMediaSelector back to false', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.showMediaSelector, false);
        });
      });

      group('when no images are selected', () {
        setUp(() {
          mockImagePicker.imagesToReturn = [];
        });

        test('keeps selectedMedia empty', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia.length, 0);
        });

        test('sets showMediaSelector to false', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.showMediaSelector, false);
        });
      });

      group('with previously selected media', () {
        setUp(() async {
          mockImagePicker.imagesToReturn = ['/path/to/image1.jpg', '/path/to/image2.jpg'];
          await notifier.handleImagesSelected();
        });

        test('appends new media to existing selection', () async {
          mockImagePicker.imagesToReturn = ['/path/to/image3.jpg'];
          await notifier.handleImagesSelected();

          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia.length, 3);
          expect(state.selectedMedia[0].originalFilePath, '/path/to/image1.jpg');
          expect(state.selectedMedia[1].originalFilePath, '/path/to/image2.jpg');
          expect(state.selectedMedia[2].originalFilePath, '/path/to/image3.jpg');
        });
      });

      group('when there is no active account', () {
        setUp(() {
          mockImagePicker.imagesToReturn = ['/path/to/image1.jpg', '/path/to/image2.jpg'];
          container.read(activePubkeyProvider.notifier).state = null;
        });

        test('keeps selectedMedia empty', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia, isEmpty);
        });

        test('sets showMediaSelector to false', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.showMediaSelector, false);
        });
      });

      group('when image picker service throws an error', () {
        setUp(() {
          mockImagePicker.errorToThrow = Exception('Image picker failed');
        });

        test('keeps selectedMedia empty', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia, isEmpty);
        });

        test('sets showMediaSelector to false', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.showMediaSelector, false);
        });

        test('does not add media when error occurs with previous media', () async {
          mockImagePicker.errorToThrow = null;
          mockImagePicker.imagesToReturn = ['/path/to/image1.jpg'];
          await notifier.handleImagesSelected();

          mockImagePicker.errorToThrow = Exception('Image picker failed');
          await notifier.handleImagesSelected();

          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia.length, 1);
          expect(state.selectedMedia[0].originalFilePath, '/path/to/image1.jpg');
        });
      });

      group('when upload to blossom server succeeds', () {
        const originalImagePath = '/path/to/image1.jpg';
        const uploadeddImagePath = '/path/to/uploaded/image1.jpg';

        setUp(() {
          mockImagePicker.imagesToReturn = [originalImagePath];
          mockUploadMedia.setUploadResult(
            originalImagePath,
            createMockMediaFile(
              filePath: uploadeddImagePath,
              id: 'uploaded-id-1',
              groupId: testGroupId,
            ),
          );
        });
        test('transitions from uploading to uploaded', () async {
          await notifier.handleImagesSelected();
          var state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia[0].isUploading, true);
          await waitForUploadsToComplete();
          state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia[0].isUploaded, true);
        });

        test('includes original file path', () async {
          await notifier.handleImagesSelected();
          await waitForUploadsToComplete();

          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia[0].originalFilePath, originalImagePath);
        });

        test('media file has uploaded path', () async {
          await notifier.handleImagesSelected();
          await waitForUploadsToComplete();

          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia[0].uploadedFile?.filePath, uploadeddImagePath);
        });
      });
      group('when upload to blossom server fails', () {
        setUp(() {
          const imagePath = '/path/to/failing-image.jpg';
          mockImagePicker.imagesToReturn = [imagePath];
          mockUploadMedia.setUploadFailure(imagePath);
        });
        test('transitions from uploading to failed', () async {
          await notifier.handleImagesSelected();
          var state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia[0].isUploading, true);
          await waitForUploadsToComplete();
          state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia[0].isFailed, true);
        });
      });

      group('when some images upload succeeds and some fail', () {
        setUp(() async {
          const image1 = '/path/to/image1.jpg';
          const image2 = '/path/to/image2.jpg';
          const image3 = '/path/to/image3.jpg';
          mockImagePicker.imagesToReturn = [image1, image2, image3];
          mockUploadMedia.setUploadResult(
            image1,
            createMockMediaFile(filePath: image1, id: 'id-1', groupId: testGroupId),
          );
          mockUploadMedia.setUploadResult(
            image2,
            createMockMediaFile(filePath: image2, id: 'id-2', groupId: testGroupId),
          );
          mockUploadMedia.setUploadFailure(image3);
          await notifier.handleImagesSelected();
        });

        test('handles upload states independently', () async {
          var state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia.every((mediaFileUpload) => mediaFileUpload.isUploading), true);
          await waitForUploadsToComplete();
          state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedMedia[0].isUploaded, true);
          expect(state.selectedMedia[1].isUploaded, true);
          expect(state.selectedMedia[2].isFailed, true);
        });

        group('with multiple selections', () {
          setUp(() async {
            mockImagePicker.imagesToReturn = ['/image1.jpg'];
            mockUploadMedia.setUploadResult(
              '/image1.jpg',
              createMockMediaFile(filePath: '/image1.jpg', id: 'id-1', groupId: testGroupId),
            );
            await notifier.handleImagesSelected();
            await waitForUploadsToComplete();

            mockImagePicker.imagesToReturn = ['/image2.jpg'];
            mockUploadMedia.setUploadFailure('/image2.jpg');
            await notifier.handleImagesSelected();
            await waitForUploadsToComplete();

            mockImagePicker.imagesToReturn = ['/image3.jpg'];
            mockUploadMedia.setUploadResult(
              '/image3.jpg',
              createMockMediaFile(filePath: '/image3.jpg', id: 'id-3', groupId: testGroupId),
            );
            await notifier.handleImagesSelected();
          });
          test('considers uploads of all selections', () async {
            final state = container.read(chatInputProvider(testGroupId));
            expect(state.selectedMedia.length, 6);
            expect(state.selectedMedia[3].isUploaded, true);
            expect(state.selectedMedia[4].isFailed, true);
            expect(state.selectedMedia[5].isUploading, true);
          });
        });
      });

      test('calls upload function with correct parameters', () async {
        const imagePath = '/path/to/image.jpg';
        mockImagePicker.imagesToReturn = [imagePath];
        mockUploadMedia.setUploadResult(
          imagePath,
          createMockMediaFile(filePath: imagePath, id: 'id-1', groupId: testGroupId),
        );

        await notifier.handleImagesSelected();
        await waitForUploadsToComplete();

        expect(mockUploadMedia.uploadCalls.length, 1);
        final call = mockUploadMedia.uploadCalls[0];
        expect(call['groupId'], testGroupId);
        expect(call['filePath'], imagePath);
        expect(call['accountPubkey'], testAccountPubkey);
      });
    });

    group('removeImage', () {
      setUp(() {
        mockImagePicker.imagesToReturn = [
          '/path/to/image1.jpg',
          '/path/to/image2.jpg',
          '/path/to/image3.jpg',
        ];
        for (final path in mockImagePicker.imagesToReturn!) {
          mockUploadMedia.setUploadResult(
            path,
            createMockMediaFile(filePath: path, id: '4', groupId: testGroupId),
          );
        }
      });

      test('removes media at valid index', () async {
        await notifier.handleImagesSelected();
        notifier.removeImage(1);
        final state = container.read(chatInputProvider(testGroupId));
        expect(state.selectedMedia.length, 2);
        expect(state.selectedMedia[0].originalFilePath, '/path/to/image1.jpg');
        expect(state.selectedMedia[1].originalFilePath, '/path/to/image3.jpg');
      });

      test('does not remove media at invalid index', () async {
        await notifier.handleImagesSelected();
        notifier.removeImage(5);

        final state = container.read(chatInputProvider(testGroupId));
        expect(state.selectedMedia.length, 3);
      });

      test('does not remove media at negative index', () async {
        await notifier.handleImagesSelected();
        notifier.removeImage(-1);
        final state = container.read(chatInputProvider(testGroupId));
        expect(state.selectedMedia.length, 3);
      });

      test('removes media in uploading state', () async {
        await notifier.handleImagesSelected();

        final stateBefore = container.read(chatInputProvider(testGroupId));
        expect(stateBefore.selectedMedia[1].isUploading, true);

        notifier.removeImage(1); // does not wait for upload to complete

        final stateAfter = container.read(chatInputProvider(testGroupId));
        expect(stateAfter.selectedMedia.length, 2);
      });

      test('removes media in uploaded state', () async {
        await notifier.handleImagesSelected();
        await waitForUploadsToComplete();
        var state = container.read(chatInputProvider(testGroupId));
        expect(state.selectedMedia[0].isUploaded, true);
        notifier.removeImage(0);
        state = container.read(chatInputProvider(testGroupId));
        expect(state.selectedMedia.length, 2);
      });

      test('removes media in failed state', () async {
        mockUploadMedia.setUploadFailure('/path/to/image2.jpg');
        await notifier.handleImagesSelected();
        await waitForUploadsToComplete();
        var state = container.read(chatInputProvider(testGroupId));
        expect(state.selectedMedia[1].isFailed, true);
        notifier.removeImage(1);
        state = container.read(chatInputProvider(testGroupId));
        expect(state.selectedMedia.length, 2);
        expect(state.selectedMedia.every((m) => m.isUploaded), true);
      });
    });

    group('clear', () {
      setUp(() async {
        mockImagePicker.imagesToReturn = ['/path/to/image1.jpg', '/path/to/image2.jpg'];
        for (final path in mockImagePicker.imagesToReturn!) {
          mockUploadMedia.setUploadResult(
            path,
            createMockMediaFile(filePath: path, id: '3', groupId: testGroupId),
          );
        }
        await notifier.handleImagesSelected();
      });

      test('clears all state including media', () async {
        mockDraftMessageService.reset();
        final stateBefore = container.read(chatInputProvider(testGroupId));
        expect(stateBefore.selectedMedia.length, 2);

        await notifier.clear();
        final state = container.read(chatInputProvider(testGroupId));

        expect(state.selectedMedia, isEmpty);
        expect(state.showMediaSelector, false);
        expect(state.isLoadingDraft, false);
        expect(state.previousEditingMessageContent, isNull);
      });

      test('calls clearDraft service', () async {
        mockDraftMessageService.reset();
        await notifier.clear();
        expect(mockDraftMessageService.clearedChats, [testGroupId]);
      });
    });

    group('setSingleLineHeight', () {
      test('sets value', () {
        notifier.setSingleLineHeight(24.0);
        expect(container.read(chatInputProvider(testGroupId)).singleLineHeight, 24.0);
      });
    });

    group('setPreviousEditingMessageContent', () {
      test('sets value', () {
        notifier.setPreviousEditingMessageContent('test message');
        expect(
          container.read(chatInputProvider(testGroupId)).previousEditingMessageContent,
          'test message',
        );
      });
    });

    group('loadDraft', () {
      group('when no draft exists', () {
        setUp(() async {
          mockDraftMessageService.draftToReturn = null;
        });
        test('returns null', () async {
          final draft = await notifier.loadDraft();
          expect(draft, isNull);
        });
      });
      group('when draft exists', () {
        setUp(() async {
          mockDraftMessageService.draftToReturn = 'test draft';
        });
        test('returns the draft', () async {
          final draft = await notifier.loadDraft();
          expect(draft, 'test draft');
        });
      });
    });

    group('scheduleDraftSave', () {
      test('saves draft after delay', () async {
        mockDraftMessageService.reset();
        notifier.scheduleDraftSave('test draft');
        expect(mockDraftMessageService.savedDrafts, isEmpty);

        await Future.delayed(const Duration(milliseconds: 10));
        expect(mockDraftMessageService.savedDrafts, ['test draft']);
      });

      test('cancels previous timer when called multiple times', () async {
        mockDraftMessageService.reset();
        notifier.scheduleDraftSave('first draft');
        notifier.scheduleDraftSave('second draft');

        await Future.delayed(const Duration(milliseconds: 10));
        expect(mockDraftMessageService.savedDrafts, ['second draft']);
      });
    });

    group('saveDraftImmediately', () {
      test('saves draft immediately', () async {
        mockDraftMessageService.reset();
        await notifier.saveDraftImmediately('immediate draft');
        expect(mockDraftMessageService.savedDrafts, ['immediate draft']);
      });

      test('cancels pending scheduled save', () async {
        mockDraftMessageService.reset();
        notifier.scheduleDraftSave('scheduled draft');
        await notifier.saveDraftImmediately('immediate draft');

        await Future.delayed(const Duration(milliseconds: 10));
        expect(mockDraftMessageService.savedDrafts, ['immediate draft']);
      });
    });

    group('hasUploadingOrFailedMedia', () {
      test('returns false when no media selected', () {
        final state = container.read(chatInputProvider(testGroupId));
        expect(state.hasUploadingOrFailedMedia, false);
      });

      group('when media is uploading', () {
        setUp(() async {
          const imagePath = '/path/to/uploading.jpg';
          mockImagePicker.imagesToReturn = [imagePath];
          mockUploadMedia.setUploadResult(
            imagePath,
            createMockMediaFile(filePath: imagePath, id: 'id-1', groupId: testGroupId),
          );
          await notifier.handleImagesSelected();
        });

        test('returns true', () {
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.hasUploadingOrFailedMedia, true);
        });
      });

      group('when media upload failed', () {
        setUp(() async {
          const imagePath = '/path/to/failed.jpg';
          mockImagePicker.imagesToReturn = [imagePath];
          mockUploadMedia.setUploadFailure(imagePath);
          await notifier.handleImagesSelected();
          await waitForUploadsToComplete();
        });

        test('returns true', () {
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.hasUploadingOrFailedMedia, true);
        });
      });

      group('when media upload succeeded', () {
        setUp(() async {
          const imagePath = '/path/to/success.jpg';
          mockImagePicker.imagesToReturn = [imagePath];
          mockUploadMedia.setUploadResult(
            imagePath,
            createMockMediaFile(filePath: imagePath, id: 'id-1', groupId: testGroupId),
          );
          await notifier.handleImagesSelected();
          await waitForUploadsToComplete();
        });

        test('returns false', () {
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.hasUploadingOrFailedMedia, false);
        });
      });

      group('when mixed media states', () {
        setUp(() async {
          const successPath = '/path/to/success.jpg';
          const failPath = '/path/to/fail.jpg';
          mockImagePicker.imagesToReturn = [successPath, failPath];
          mockUploadMedia.setUploadResult(
            successPath,
            createMockMediaFile(filePath: successPath, id: 'id-1', groupId: testGroupId),
          );
          mockUploadMedia.setUploadFailure(failPath);
          await notifier.handleImagesSelected();
          await waitForUploadsToComplete();
        });

        test('returns true', () {
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.hasUploadingOrFailedMedia, true);
        });
      });
    });

    group('sendMessage', () {
      group('when not replying', () {
        setUp(() {
          final mockMessage = MessageWithTokens(
            id: 'sent-message-id',
            pubkey: testAccountPubkey,
            kind: 9,
            createdAt: DateTime(2025, 1, 3),
            content: 'Test message',
            tokens: [],
          );
          mockChatProvider.setMessageToReturn(mockMessage);
        });

        test('sends message', () async {
          await notifier.sendMessage(message: 'Hello world');
          expect(mockChatProvider.sendMessageCalls.length, 1);
        });

        test('sends message with expected arguments', () async {
          await notifier.sendMessage(message: 'Hello world');
          final sendMessageCall = mockChatProvider.sendMessageCalls[0];
          expect(sendMessageCall['groupId'], testGroupId);
          expect(sendMessageCall['message'], 'Hello world');
          expect(sendMessageCall['isEditing'], false);
          expect(sendMessageCall['mediaFiles'], isEmpty);
        });

        test('returns sent message', () async {
          final result = await notifier.sendMessage(message: 'Hello world');
          expect(result?.id, 'sent-message-id');
          expect(result?.pubkey, testAccountPubkey);
        });

        test('clears draft after sending', () async {
          mockDraftMessageService.reset();
          await notifier.sendMessage(message: 'Hello world');
          expect(mockDraftMessageService.clearedChats, [testGroupId]);
        });

        group('when media is still uploading', () {
          setUp(() async {
            const imagePathA = '/path/to/uploadingImage.jpg';
            mockImagePicker.imagesToReturn = [imagePathA];
            mockUploadMedia.setUploadResult(
              imagePathA,
              createMockMediaFile(filePath: imagePathA, id: 'id-1', groupId: testGroupId),
            );

            await notifier.handleImagesSelected();
          });
          test('does not send message', () async {
            final result = await notifier.sendMessage(message: 'Hello world');

            expect(result, isNull);
            expect(mockChatProvider.sendMessageCalls, isEmpty);
          });

          test('does not clear chat', () async {
            await notifier.sendMessage(message: 'Hello world');
            expect(mockDraftMessageService.clearedChats, isEmpty);
          });

          test('does not clear selected media', () async {
            await notifier.sendMessage(message: 'Hello world');
            final state = container.read(chatInputProvider(testGroupId));
            expect(state.selectedMedia, isNotEmpty);
          });
        });

        group('when some media uploads are failed', () {
          setUp(() async {
            const imagePathA = '/path/to/failingImage.jpg';
            mockImagePicker.imagesToReturn = [imagePathA];
            mockUploadMedia.setUploadFailure(imagePathA);
            await notifier.handleImagesSelected();
            await waitForUploadsToComplete();
          });
          test('does not send message', () async {
            final result = await notifier.sendMessage(message: 'Hello world');
            expect(result, isNull);
            expect(mockChatProvider.sendMessageCalls, isEmpty);
          });

          test('does not clear chat', () async {
            await notifier.sendMessage(message: 'Hello world');
            expect(mockDraftMessageService.clearedChats, isEmpty);
          });

          test('does not clear selected media', () async {
            await notifier.sendMessage(message: 'Hello world');
            final state = container.read(chatInputProvider(testGroupId));
            expect(state.selectedMedia, isNotEmpty);
          });
        });

        group('when editing a message', () {
          test('sends message with isEditing flag set to true', () async {
            await notifier.sendMessage(message: 'Hello world', isEditing: true);
            final sendMessageCall = mockChatProvider.sendMessageCalls[0];
            expect(sendMessageCall['isEditing'], true);
          });
        });

        group('with media files', () {
          setUp(() async {
            const imagePathA = '/path/to/imageA.jpg';
            const imagePathB = '/path/to/imageB.jpg';
            mockImagePicker.imagesToReturn = [imagePathA, imagePathB];
            mockUploadMedia.setUploadResult(
              imagePathA,
              createMockMediaFile(filePath: imagePathA, id: 'id-1', groupId: testGroupId),
            );
            mockUploadMedia.setUploadResult(
              imagePathB,
              createMockMediaFile(filePath: imagePathB, id: 'id-2', groupId: testGroupId),
            );
            await notifier.handleImagesSelected();
            await waitForUploadsToComplete();
          });
          test('sends message with selected media files', () async {
            await notifier.sendMessage(message: 'Check this out');
            final call = mockChatProvider.sendMessageCalls[0];
            expect(call['mediaFiles'], hasLength(2));
          });

          test('clears selected media after sending', () async {
            final previousState = container.read(chatInputProvider(testGroupId));
            expect(previousState.selectedMedia.length, 2);
            await notifier.sendMessage(message: 'Check this out');
            final state = container.read(chatInputProvider(testGroupId));
            expect(state.selectedMedia, isEmpty);
          });
        });

        group('with mixed media states (some failed, some uploaded)', () {
          setUp(() async {
            mockDraftMessageService.reset();
            const imagePathA = '/path/to/successImage.jpg';
            const imagePathB = '/path/to/failedImage.jpg';
            const imagePathC = '/path/to/anotherSuccessImage.jpg';

            mockImagePicker.imagesToReturn = [imagePathA, imagePathB, imagePathC];
            mockUploadMedia.setUploadResult(
              imagePathA,
              createMockMediaFile(filePath: imagePathA, id: 'id-1', groupId: testGroupId),
            );
            mockUploadMedia.setUploadFailure(imagePathB);
            mockUploadMedia.setUploadResult(
              imagePathC,
              createMockMediaFile(filePath: imagePathC, id: 'id-3', groupId: testGroupId),
            );

            await notifier.handleImagesSelected();
            await waitForUploadsToComplete();
          });

          test('does not send message', () async {
            final result = await notifier.sendMessage(message: 'Partial upload');

            expect(mockChatProvider.sendMessageCalls, isEmpty);
            expect(result, isNull);
          });

          test('does not clear chat', () async {
            await notifier.sendMessage(message: 'Partial upload');
            expect(mockDraftMessageService.clearedChats, isEmpty);
          });

          test('does not clear selected media', () async {
            await notifier.sendMessage(message: 'Partial upload');
            final state = container.read(chatInputProvider(testGroupId));
            expect(state.selectedMedia, isNotEmpty);
          });
        });
      });

      group('when replying', () {
        const replyToMessageId = 'original-message-id';
        late MessageModel replyToMessage;

        setUp(() {
          final testSender = User(
            id: testAccountPubkey,
            displayName: 'Test User',
            nip05: '',
            publicKey: testAccountPubkey,
          );

          replyToMessage = MessageModel(
            id: replyToMessageId,
            type: MessageType.text,
            createdAt: DateTime(2025, 1, 3),
            content: 'Original message content',
            sender: testSender,
            isMe: true,
          );

          final chatStateWithReply = ChatState(
            replyingTo: {testGroupId: replyToMessage},
          );
          mockChatProvider.setChatState(chatStateWithReply);

          final mockMessage = MessageWithTokens(
            id: 'reply-message-id',
            pubkey: testAccountPubkey,
            kind: 9,
            createdAt: DateTime(2025, 1, 3),
            content: 'Reply message',
            tokens: [],
          );
          mockChatProvider.setMessageToReturn(mockMessage);
        });

        test('sends reply message', () async {
          await notifier.sendMessage(message: 'This is a reply');
          expect(mockChatProvider.sendReplyMessageCalls.length, 1);
        });

        test('sends reply with expected arguments', () async {
          await notifier.sendMessage(message: 'This is a reply');
          final sendReplyCall = mockChatProvider.sendReplyMessageCalls[0];
          expect(sendReplyCall['groupId'], testGroupId);
          expect(sendReplyCall['replyToMessageId'], replyToMessageId);
          expect(sendReplyCall['message'], 'This is a reply');
          expect(sendReplyCall['mediaFiles'], isEmpty);
        });

        test('does not call regular sendMessage when replying', () async {
          await notifier.sendMessage(message: 'This is a reply');
          expect(mockChatProvider.sendMessageCalls, isEmpty);
        });

        test('returns sent reply message', () async {
          final result = await notifier.sendMessage(message: 'This is a reply');
          expect(result?.id, 'reply-message-id');
        });

        test('clears draft after sending reply', () async {
          mockDraftMessageService.reset();
          await notifier.sendMessage(message: 'This is a reply');
          expect(mockDraftMessageService.clearedChats, [testGroupId]);
        });

        test('does not clear state when reply send fails', () async {
          mockChatProvider.setMessageToReturn(null); // Simulate send failure
          mockDraftMessageService.reset();

          final result = await notifier.sendMessage(message: 'This is a reply');

          expect(result, isNull);
          expect(mockDraftMessageService.clearedChats, isEmpty);
        });

        group('with media files', () {
          setUp(() async {
            const imagePathA = '/path/to/replyImageA.jpg';
            const imagePathB = '/path/to/replyImageB.jpg';
            mockImagePicker.imagesToReturn = [imagePathA, imagePathB];
            mockUploadMedia.setUploadResult(
              imagePathA,
              createMockMediaFile(filePath: imagePathA, id: 'reply-id-1', groupId: testGroupId),
            );
            mockUploadMedia.setUploadResult(
              imagePathB,
              createMockMediaFile(filePath: imagePathB, id: 'reply-id-2', groupId: testGroupId),
            );
            await notifier.handleImagesSelected();
            await waitForUploadsToComplete();
          });

          test('sends reply message once', () async {
            await notifier.sendMessage(message: 'Reply with images');
            expect(mockChatProvider.sendReplyMessageCalls.length, 1);
          });

          test('sends reply with expected amount of media files', () async {
            await notifier.sendMessage(message: 'Reply with images');
            final call = mockChatProvider.sendReplyMessageCalls[0];
            expect(call['groupId'], testGroupId);
            expect(call['replyToMessageId'], replyToMessageId);
            expect(call['message'], 'Reply with images');
            expect(call['mediaFiles'], hasLength(2));
          });

          test('clears selected media after sending reply', () async {
            final previousState = container.read(chatInputProvider(testGroupId));
            expect(previousState.selectedMedia.length, 2);
            await notifier.sendMessage(message: 'Reply with images');
            final state = container.read(chatInputProvider(testGroupId));
            expect(state.selectedMedia, isEmpty);
          });
        });
      });
    });
  });
}
