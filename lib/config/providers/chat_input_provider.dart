import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/domain/services/draft_message_service.dart';
import 'package:whitenoise/domain/services/image_picker_service.dart';
import 'package:whitenoise/src/rust/api/media.dart' as rust_media;
import 'package:whitenoise/ui/chat/states/chat_input_state.dart';
import 'package:whitenoise/ui/chat/states/media_file_upload.dart';

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  ChatInputNotifier({
    required String groupId,
    ImagePickerService? imagePickerService,
    DraftMessageService? draftMessageService,
    Duration draftSaveDelay = const Duration(milliseconds: 500),
  }) : _groupId = groupId,
       _imagePickerService = imagePickerService ?? ImagePickerService(),
       _draftMessageService = draftMessageService ?? DraftMessageService(),
       _draftSaveDelay = draftSaveDelay,
       super(const ChatInputState());

  static final _logger = Logger('ChatInputNotifier');
  final String _groupId;
  final ImagePickerService _imagePickerService;
  final DraftMessageService _draftMessageService;
  final Duration _draftSaveDelay;
  Timer? _draftSaveTimer;

  Future<String?> loadDraft() async {
    state = state.copyWith(isLoadingDraft: true);
    try {
      final draft = await _draftMessageService.loadDraft(chatId: _groupId);
      return draft;
    } finally {
      if (mounted) {
        state = state.copyWith(isLoadingDraft: false);
      }
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
    final imagePaths = await _imagePickerService.pickMultipleImages();
    if (imagePaths.isEmpty) {
      state = state.copyWith(showMediaSelector: false);
      return;
    }

    // Hide media selector and add images in uploading state
    final uploadingItems =
        imagePaths
            .map(
              (path) => MediaFileUpload.uploading(filePath: path),
            )
            .toList();

    state = state.copyWith(
      showMediaSelector: false,
      selectedMedia: [...state.selectedMedia, ...uploadingItems],
    );

    // Upload each image
    for (final path in imagePaths) {
      _uploadImage(path);
    }
  }

  Future<void> _uploadImage(String filePath) async {
    try {
      // Upload the image to blossom server
      final mediaFile = await rust_media.uploadMedia(
        accountPubkey: 'temp_pubkey', // TODO: Get actual account pubkey
        groupId: _groupId,
        filePath: filePath,
      );

      // Update the item from uploading to uploaded
      final updatedMedia =
          state.selectedMedia.map((item) {
            return item.maybeWhen(
              uploading:
                  (path) => path == filePath ? MediaFileUpload.uploaded(file: mediaFile) : item,
              orElse: () => item,
            );
          }).toList();

      state = state.copyWith(selectedMedia: updatedMedia);
    } catch (e, st) {
      _logger.severe('Failed to upload image: $filePath', e, st);

      // Update the item to failed state
      final updatedMedia =
          state.selectedMedia.map((item) {
            return item.maybeWhen(
              uploading:
                  (path) =>
                      path == filePath
                          ? MediaFileUpload.failed(filePath: path, error: e.toString())
                          : item,
              orElse: () => item,
            );
          }).toList();

      state = state.copyWith(selectedMedia: updatedMedia);
    }
  }

  void removeImage(int index) {
    if (index < 0 || index >= state.selectedMedia.length) {
      _logger.warning('Invalid image index: $index');
      return;
    }
    final updatedMedia = List<MediaFileUpload>.from(state.selectedMedia);
    updatedMedia.removeAt(index);
    state = state.copyWith(selectedMedia: updatedMedia);
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
      selectedMedia: [],
    );
  }

  @override
  void dispose() {
    _draftSaveTimer?.cancel();
    super.dispose();
  }
}

final chatInputProvider = StateNotifierProvider.family<ChatInputNotifier, ChatInputState, String>(
  (ref, groupId) => ChatInputNotifier(groupId: groupId),
);
