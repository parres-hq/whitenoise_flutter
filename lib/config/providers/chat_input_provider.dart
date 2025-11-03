import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:whitenoise/config/providers/active_pubkey_provider.dart';
import 'package:whitenoise/config/providers/chat_provider.dart';
import 'package:whitenoise/domain/models/media_file_upload.dart';
import 'package:whitenoise/domain/services/draft_message_service.dart';
import 'package:whitenoise/domain/services/image_picker_service.dart';
import 'package:whitenoise/src/rust/api/media_files.dart' as rust_media_files;
import 'package:whitenoise/src/rust/api/messages.dart' show MessageWithTokens;
import 'package:whitenoise/ui/chat/states/chat_input_state.dart';

import 'package:whitenoise/utils/pubkey_formatter.dart';

class ChatInputNotifier extends FamilyNotifier<ChatInputState, String> {
  ChatInputNotifier({
    ImagePickerService? imagePickerService,
    DraftMessageService? draftMessageService,
    Duration draftSaveDelay = const Duration(milliseconds: 500),
    Future<rust_media_files.MediaFile> Function({
      required String accountPubkey,
      required String groupId,
      required String filePath,
    })?
    uploadMediaFn,
  }) : _imagePickerService = imagePickerService ?? ImagePickerService(),
       _draftMessageService = draftMessageService ?? DraftMessageService(),
       _draftSaveDelay = draftSaveDelay,
       _uploadMediaFn = uploadMediaFn ?? rust_media_files.uploadChatMedia;

  static final _logger = Logger('ChatInputNotifier');
  late final String _groupId;
  late String _accountHexPubkey;
  final ImagePickerService _imagePickerService;
  final DraftMessageService _draftMessageService;
  final Duration _draftSaveDelay;
  final Future<rust_media_files.MediaFile> Function({
    required String accountPubkey,
    required String groupId,
    required String filePath,
  })
  _uploadMediaFn;
  Timer? _draftSaveTimer;

  @override
  ChatInputState build(String groupId) {
    _groupId = groupId;
    final accountPubkey = ref.read(activePubkeyProvider);
    _accountHexPubkey = PubkeyFormatter(pubkey: accountPubkey).toHex() ?? '';

    ref.listen<String?>(activePubkeyProvider, (previous, next) {
      if (previous != next) {
        final newAccountHexPubkey = PubkeyFormatter(pubkey: next).toHex() ?? '';
        if (_accountHexPubkey != newAccountHexPubkey) {
          _draftSaveTimer?.cancel();
          _accountHexPubkey = newAccountHexPubkey;
        }
      }
    });

    ref.onDispose(() {
      _draftSaveTimer?.cancel();
    });
    return const ChatInputState();
  }

  Future<void> handleAccountSwitch({
    required String? oldPubkey,
    required String currentText,
  }) async {
    if (oldPubkey == null || currentText.isEmpty) return;

    final oldAccountHexPubkey = PubkeyFormatter(pubkey: oldPubkey).toHex();
    if (oldAccountHexPubkey != null && oldAccountHexPubkey.isNotEmpty) {
      await _draftMessageService.saveDraft(
        accountId: oldAccountHexPubkey,
        chatId: _groupId,
        message: currentText,
      );
    }
  }

  Future<String?> loadDraft() async {
    state = state.copyWith(isLoadingDraft: true);
    try {
      final accountPubkey = ref.read(activePubkeyProvider);
      final accountHexPubkey = PubkeyFormatter(pubkey: accountPubkey).toHex() ?? '';
      if (accountHexPubkey.isEmpty) return null;

      _accountHexPubkey = accountHexPubkey;

      final draft = await _draftMessageService.loadDraft(
        accountId: accountHexPubkey,
        chatId: _groupId,
      );
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
    final accountPubkey = ref.read(activePubkeyProvider);
    final accountHexPubkey = PubkeyFormatter(pubkey: accountPubkey).toHex() ?? '';
    if (accountHexPubkey.isEmpty) return;

    _accountHexPubkey = accountHexPubkey;

    await _draftMessageService.saveDraft(
      accountId: accountHexPubkey,
      chatId: _groupId,
      message: text,
    );
  }

  void hideMediaSelector() {
    state = state.copyWith(showMediaSelector: false);
  }

  void toggleMediaSelector() {
    state = state.copyWith(showMediaSelector: !state.showMediaSelector);
  }

  Future<void> handleImagesSelected() async {
    final accountPubkey = ref.read(activePubkeyProvider);
    final accountHexPubkey = PubkeyFormatter(pubkey: accountPubkey).toHex() ?? '';
    if (accountHexPubkey.isEmpty) {
      state = state.copyWith(showMediaSelector: false);
      return;
    }
    try {
      final imagePaths = await _imagePickerService.pickMultipleImages();
      if (imagePaths.isEmpty) {
        state = state.copyWith(showMediaSelector: false);
        return;
      }
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
      for (final path in imagePaths) {
        unawaited(_uploadImage(filePath: path, accountHexPubkey: accountHexPubkey));
      }
    } catch (e) {
      _logger.warning('Failed to select images for group $_groupId', e);
      state = state.copyWith(showMediaSelector: false);
      return;
    }
  }

  Future<void> _uploadImage({required String filePath, required String accountHexPubkey}) async {
    try {
      final mediaFile = await _uploadMediaFn(
        accountPubkey: accountHexPubkey,
        groupId: _groupId,
        filePath: filePath,
      );
      final updatedMedia =
          state.selectedMedia.map((item) {
            return item.maybeWhen(
              uploading:
                  (path) =>
                      path == filePath
                          ? MediaFileUpload.uploaded(file: mediaFile, originalFilePath: filePath)
                          : item,
              orElse: () => item,
            );
          }).toList();

      state = state.copyWith(selectedMedia: updatedMedia);
    } catch (e, st) {
      _logger.severe('Failed to upload image: $filePath', e, st);
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

  Future<MessageWithTokens?> sendMessage({
    required String message,
    bool isEditing = false,
  }) async {
    if (state.hasUploadingMedia || state.hasFailedMedia) return null;

    final uploadedMediaFiles =
        state.selectedMedia
            .where((media) => media.uploadedFile != null)
            .map((media) => media.uploadedFile!)
            .toList();

    final chatProviderState = ref.read(chatProvider);
    final replyingTo = chatProviderState.replyingTo[_groupId];
    final chatNotifier = ref.read(chatProvider.notifier);
    late MessageWithTokens? messageSent;
    if (replyingTo != null) {
      messageSent = await chatNotifier.sendReplyMessage(
        groupId: _groupId,
        replyToMessageId: replyingTo.id,
        message: message,
        mediaFiles: uploadedMediaFiles,
      );
    } else {
      messageSent = await chatNotifier.sendMessage(
        groupId: _groupId,
        message: message,
        isEditing: isEditing,
        mediaFiles: uploadedMediaFiles,
      );
    }

    if (messageSent != null) {
      await clear();
    }

    return messageSent;
  }

  Future<void> clear() async {
    _draftSaveTimer?.cancel();

    final accountPubkey = ref.read(activePubkeyProvider);
    final accountHexPubkey = PubkeyFormatter(pubkey: accountPubkey).toHex() ?? '';
    if (accountHexPubkey.isNotEmpty) {
      _accountHexPubkey = accountHexPubkey;

      await _draftMessageService.clearDraft(
        accountId: accountHexPubkey,
        chatId: _groupId,
      );
    }
    state = state.copyWith(
      showMediaSelector: false,
      isLoadingDraft: false,
      previousEditingMessageContent: null,
      selectedMedia: [],
    );
  }
}

final chatInputProvider = NotifierProvider.family<ChatInputNotifier, ChatInputState, String>(
  ChatInputNotifier.new,
);
