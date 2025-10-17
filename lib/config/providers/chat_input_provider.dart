import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/services/draft_message_service.dart';
import 'package:whitenoise/domain/services/image_picker_service.dart';
import 'package:whitenoise/ui/chat/states/chat_input_state.dart';

class ChatInputNotifier extends FamilyNotifier<ChatInputState, String> {
  ChatInputNotifier({
    ImagePickerService? imagePickerService,
    DraftMessageService? draftMessageService,
    Duration draftSaveDelay = const Duration(milliseconds: 500),
  }) : _imagePickerService = imagePickerService ?? ImagePickerService(),
       _draftMessageService = draftMessageService ?? DraftMessageService(),
       _draftSaveDelay = draftSaveDelay;

  static final _logger = Logger('ChatInputNotifier');
  late final String _groupId;
  final ImagePickerService _imagePickerService;
  final DraftMessageService _draftMessageService;
  final Duration _draftSaveDelay;
  Timer? _draftSaveTimer;

  @override
  ChatInputState build(String groupId) {
    _groupId = groupId;
    ref.onDispose(() {
      _draftSaveTimer?.cancel();
    });
    return const ChatInputState();
  }

  Future<String?> loadDraft() async {
    state = state.copyWith(isLoadingDraft: true);
    try {
      final draft = await _draftMessageService.loadDraft(chatId: _groupId);
      return draft;
    } finally {
      state = state.copyWith(isLoadingDraft: false);
    }
  }

  void scheduleDraftSave(String text) {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(
      _draftSaveDelay,
      () => _saveDraft(text),
    );
  }

  Future<void> saveDraftImmediately(String text) async {
    _draftSaveTimer?.cancel();
    await _saveDraft(text);
  }

  Future<void> _saveDraft(String text) async {
    await _draftMessageService.saveDraft(chatId: _groupId, message: text);
  }

  void hideMediaSelector() {
    state = state.copyWith(showMediaSelector: false);
  }

  void toggleMediaSelector() {
    state = state.copyWith(showMediaSelector: !state.showMediaSelector);
  }

  Future<void> handleImagesSelected() async {
    try {
      final imagePaths = await _imagePickerService.pickMultipleImages();
      if (imagePaths.isNotEmpty) {
        state = state.copyWith(
          showMediaSelector: false,
          selectedImages: [...state.selectedImages, ...imagePaths],
        );
      } else {
        state = state.copyWith(showMediaSelector: false);
      }
    } catch (e) {
      _logger.warning('Failed to select images for group $_groupId', e);
      state = state.copyWith(showMediaSelector: false);
    }
  }

  void removeImage(int index) {
    if (index < 0 || index >= state.selectedImages.length) {
      _logger.warning('Invalid image index: $index');
      return;
    }
    final updatedImages = List<String>.from(state.selectedImages);
    updatedImages.removeAt(index);
    state = state.copyWith(selectedImages: updatedImages);
  }

  void setSingleLineHeight(double height) {
    if (state.singleLineHeight != height) {
      state = state.copyWith(singleLineHeight: height);
    }
  }

  void setPreviousEditingMessageContent(String? content) {
    state = state.copyWith(previousEditingMessageContent: content);
  }

  Future<void> clear() async {
    _draftSaveTimer?.cancel();
    await _draftMessageService.clearDraft(chatId: _groupId);
    state = state.copyWith(
      showMediaSelector: false,
      isLoadingDraft: false,
      previousEditingMessageContent: null,
      selectedImages: [],
    );
  }
}

final chatInputProvider = NotifierProvider.family<ChatInputNotifier, ChatInputState, String>(
  ChatInputNotifier.new,
);
