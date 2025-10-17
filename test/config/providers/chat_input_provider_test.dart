import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/chat_input_provider.dart';
import 'package:whitenoise/domain/services/draft_message_service.dart';
import 'package:whitenoise/domain/services/image_picker_service.dart';
import 'package:whitenoise/ui/chat/states/chat_input_state.dart';

class MockImagePickerService extends ImagePickerService {
  List<String>? imagesToReturn;
  Exception? errorToThrow;

  @override
  Future<List<String>> pickMultipleImages() async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return imagesToReturn ?? [];
  }
}

class MockDraftMessageService extends DraftMessageService {
  String? draftToReturn;
  final List<String> savedDrafts = [];
  final List<String> clearedChats = [];

  @override
  Future<String?> loadDraft({required String chatId, FlutterSecureStorage? storage}) async {
    return draftToReturn;
  }

  @override
  Future<void> saveDraft({
    required String chatId,
    required String message,
    FlutterSecureStorage? storage,
  }) async {
    savedDrafts.add(message);
    draftToReturn = message;
  }

  @override
  Future<void> clearDraft({required String chatId, FlutterSecureStorage? storage}) async {
    clearedChats.add(chatId);
    draftToReturn = null;
  }

  void reset() {
    savedDrafts.clear();
    clearedChats.clear();
    draftToReturn = null;
  }
}

void main() {
  group('ChatInputProvider Tests', () {
    late ProviderContainer container;
    late ChatInputNotifier notifier;
    late MockImagePickerService mockImagePicker;
    late MockDraftMessageService mockDraftMessageService;
    const testGroupId = 'test-group-id';
    const testDraftSaveDelay = Duration(milliseconds: 5);

    setUp(() {
      mockImagePicker = MockImagePickerService();
      mockDraftMessageService = MockDraftMessageService();
      container = ProviderContainer(
        overrides: [
          chatInputProvider.overrideWith(
            () => ChatInputNotifier(
              imagePickerService: mockImagePicker,
              draftMessageService: mockDraftMessageService,
              draftSaveDelay: testDraftSaveDelay,
            ),
          ),
        ],
      );
      notifier = container.read(chatInputProvider(testGroupId).notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('has expected initial state', () {
      final testContainer = ProviderContainer();
      final state = testContainer.read(chatInputProvider('test-group-123'));
      expect(state, isA<ChatInputState>());
      expect(state.isLoadingDraft, false);
      expect(state.showMediaSelector, false);
      expect(state.selectedImages, isEmpty);
      expect(state.singleLineHeight, isNull);
      expect(state.previousEditingMessageContent, isNull);
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
        test('adds images to selectedImages', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedImages.length, 2);
          expect(state.selectedImages, contains('/path/to/image1.jpg'));
          expect(state.selectedImages, contains('/path/to/image2.jpg'));
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
        test('keeps selectedImages empty', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedImages.length, 0);
        });
        test('sets showMediaSelector to false', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.showMediaSelector, false);
        });
      });

      group('with previously selected images', () {
        setUp(() async {
          mockImagePicker.imagesToReturn = ['/path/to/image1.jpg', '/path/to/image2.jpg'];
          await notifier.handleImagesSelected();
        });

        test('appends new images to existing selection selectedImages', () async {
          mockImagePicker.imagesToReturn = ['/path/to/image3.jpg'];
          await notifier.handleImagesSelected();

          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedImages.length, 3);
          expect(state.selectedImages[0], '/path/to/image1.jpg');
          expect(state.selectedImages[1], '/path/to/image2.jpg');
          expect(state.selectedImages[2], '/path/to/image3.jpg');
        });
      });

      group('when image picker service throws an error', () {
        setUp(() {
          mockImagePicker.errorToThrow = Exception('Image picker failed');
        });

        test('keeps selectedImages empty', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedImages, isEmpty);
        });

        test('sets showMediaSelector to false', () async {
          await notifier.handleImagesSelected();
          final state = container.read(chatInputProvider(testGroupId));
          expect(state.showMediaSelector, false);
        });

        test('does not add images when error occurs with previous images', () async {
          mockImagePicker.errorToThrow = null;
          mockImagePicker.imagesToReturn = ['/path/to/image1.jpg'];
          await notifier.handleImagesSelected();

          mockImagePicker.errorToThrow = Exception('Image picker failed');
          await notifier.handleImagesSelected();

          final state = container.read(chatInputProvider(testGroupId));
          expect(state.selectedImages.length, 1);
          expect(state.selectedImages[0], '/path/to/image1.jpg');
        });
      });
    });

    group('removeImage', () {
      setUp(() {
        mockImagePicker.imagesToReturn = [
          '/path/to/image1.jpg',
          '/path/to/image2.jpg',
          '/path/to/image3.jpg',
        ];
      });
      test('removes image at valid index', () async {
        await notifier.handleImagesSelected();
        notifier.removeImage(1);
        final state = container.read(chatInputProvider(testGroupId));
        expect(state.selectedImages.length, 2);
        expect(state.selectedImages[0], '/path/to/image1.jpg');
        expect(state.selectedImages[1], '/path/to/image3.jpg');
      });

      test('does not remove image at invalid index', () async {
        await notifier.handleImagesSelected();
        notifier.removeImage(5);

        final state = container.read(chatInputProvider(testGroupId));
        expect(state.selectedImages.length, 3);
      });

      test('does not remove image at negative index', () async {
        await notifier.handleImagesSelected();
        notifier.removeImage(-1);
        final state = container.read(chatInputProvider(testGroupId));
        expect(state.selectedImages.length, 3);
      });
    });

    group('clear', () {
      setUp(() async {
        mockImagePicker.imagesToReturn = ['/path/to/image1.jpg', '/path/to/image2.jpg'];
        await notifier.handleImagesSelected();
      });

      test('clears all state', () async {
        mockDraftMessageService.reset();
        await notifier.clear();
        final state = container.read(chatInputProvider(testGroupId));

        expect(state.selectedImages, isEmpty);
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
  });
}
