// chat_input.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/ui/chat/widgets/chat_input/stacked_images.dart';

import 'chat_input_providers.dart';
import 'components/audio_player_widget.dart';
import 'components/emoji_picker_widget.dart';
import 'components/reply_edit_header.dart';
import 'components/recording_ui.dart';
import 'components/text_input_ui.dart';

class ChatInput extends ConsumerWidget {
  const ChatInput({
    super.key,
    required this.currentUser,
    required this.onSend,
    this.onAttachmentPressed,
    this.cursorColor,
    this.enableAudio = true,
    this.enableImages = true,
    this.mediaSelector,
    this.imageSource = ImageSource.gallery,
    this.padding = const EdgeInsets.all(4.0),
    this.replyingTo,
    this.editingMessage,
    this.onCancelReply,
    this.onCancelEdit,
  });

  final User currentUser;
  final void Function(MessageModel message, bool isEditing) onSend;
  final VoidCallback? onAttachmentPressed;
  final EdgeInsetsGeometry padding;
  final Color? cursorColor;
  final bool enableAudio;
  final bool enableImages;
  final Widget? mediaSelector;
  final ImageSource imageSource;
  final MessageModel? replyingTo;
  final MessageModel? editingMessage;
  final VoidCallback? onCancelReply;
  final VoidCallback? onCancelEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatInputStateProvider);
    final notifier = ref.read(chatInputStateProvider.notifier);

    // Format recording time
    final formattedRecordingTime = _formatRecordingTime(state.recordingDurationSeconds);

    // Determine if we have content
    final hasTextContent = state.message.trim().isNotEmpty;
    final hasMediaContent = state.selectedImages.isNotEmpty || state.recordedFilePath != null;
    final hasContent = hasTextContent || hasMediaContent;

    return Column(
      children: [
        // Reply/Edit header
        if (replyingTo != null || editingMessage != null)
          ReplyEditHeader(
            replyingTo: replyingTo,
            editingMessage: editingMessage,
            onCancel: () {
              if (replyingTo != null) {
                onCancelReply?.call();
              } else {
                onCancelEdit?.call();
              }
            },
          ),

        // Selected images preview
        if (state.selectedImages.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: StackedImages(
              imageUris: state.selectedImages.map((e) => e.path).toList(),
              onDelete: notifier.clearSelectedImages,
            ),
          ),

        // Audio player for recorded audio
        if (state.recordedFilePath != null && !state.isRecording)
          AudioPlayerWidget(
            audioPath: state.recordedFilePath!,
            onDelete: notifier.clearRecordedAudio,
          ),

        // Main input area
        Padding(
          padding: padding,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: SizeTransition(sizeFactor: animation, child: child)),
            child: state.isRecording
                ? RecordingUI(
                    recordingTime: formattedRecordingTime,
                    onDragUpdate: (details) => notifier.handleDragUpdate(details.delta.dx),
                    onDragEnd: (_) => notifier.handleDragEnd(),
                    onDragStart: (_) => notifier.handleDragStart(),
                    dragOffsetX: state.dragOffsetX,
                    isDragging: state.isDragging,
                  )
                : TextInputUI(
                    message: state.message,
                    onMessageChanged: notifier.updateMessage,
                    focusNode: FocusNode(),
                    showEmojiPicker: state.showEmojiPicker,
                    hasContent: hasContent,
                    enableAudio: enableAudio,
                    enableImages: enableImages,
                    isRecording: state.isRecording,
                    mediaSelector: mediaSelector,
                    cursorColor: cursorColor,
                    onPickImages: () => notifier.pickImages(imageSource),
                    onSendMessage: () => _sendMessage(ref),
                    onToggleEmojiPicker: notifier.toggleEmojiPicker,
                    onStartRecording: notifier.startRecording,
                    onAttachmentPressed: onAttachmentPressed,
                  ),
          ),
        ),

        // Emoji picker
        if (state.showEmojiPicker)
          EmojiPickerWidget(
            onEmojiSelected: (emoji) {
              notifier.updateMessage(state.message + emoji.emoji);
            },
            onBackspacePressed: () {
              if (state.message.isNotEmpty) {
                notifier.updateMessage(state.message.substring(0, state.message.length - 1));
              }
            },
          ),
      ],
    );
  }

  String _formatRecordingTime(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  void _sendMessage(WidgetRef ref) {
    final state = ref.read(chatInputStateProvider);
    final notifier = ref.read(chatInputStateProvider.notifier);
    final isEditing = editingMessage != null;

    debugPrint(state.message.trim());

    final message = MessageModel(
      id: editingMessage?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: state.message.trim(),
      type: state.recordedFilePath != null
          ? MessageType.audio
          : state.selectedImages.isNotEmpty
              ? MessageType.image
              : MessageType.text,
      createdAt: editingMessage?.createdAt ?? DateTime.now(),
      updatedAt: editingMessage != null ? DateTime.now() : null,
      sender: currentUser,
      isMe: true,
      status: MessageStatus.sending,
      audioPath: state.recordedFilePath,
      imageUrl: state.selectedImages.isNotEmpty ? state.selectedImages.first.path : null,
      replyTo: replyingTo,
    );

    onSend(message, isEditing);
    notifier.resetState();
  }
}