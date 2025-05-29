import 'dart:io';
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

class ChatInput extends ConsumerStatefulWidget {
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
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  late FocusNode _focusNode;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _initializeForEditing();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editingMessage != oldWidget.editingMessage) {
      _initializeForEditing();
    }
  }

  Future<void> _initializeForEditing() async {
    if (widget.editingMessage == null) return;

    setState(() => _isInitializing = true);
    final notifier = ref.read(chatInputStateProvider.notifier);

    try {
      // Initialize basic message content
      notifier.updateMessage(widget.editingMessage!.content ?? '');

      // Handle different message types
      switch (widget.editingMessage!.type) {
        case MessageType.audio:
          if (widget.editingMessage!.audioPath != null) {
            notifier.state = notifier.state.copyWith(
              recordedFilePath: widget.editingMessage!.audioPath,
            );
          }
          break;

        case MessageType.image:
          if (widget.editingMessage!.imageUrl != null) {
            final xFile = await _createXFileFromUrl(widget.editingMessage!.imageUrl!);
            if (xFile != null) {
              notifier.state = notifier.state.copyWith(selectedImages: [xFile]);
            }
          }
          break;

        case MessageType.text:
        default:
          // No additional handling needed for text messages
          break;
      }

      // Focus the input field
      _focusNode.requestFocus();
    } catch (e) {
      debugPrint('Error initializing for editing: $e');
    } finally {
      setState(() => _isInitializing = false);
    }
  }

  Future<XFile?> _createXFileFromUrl(String url) async {
    try {
      if (url.startsWith('http')) {
        // For network images - download first
        final response = await HttpClient().getUrl(Uri.parse(url));
        final request = await response.close();
        final bytes = await request.fold(
          <int>[],
          (List<int> accumulator, List<int> bytes) => accumulator..addAll(bytes),
        );

        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes(bytes);
        return XFile(file.path);
      } else {
        // For local files
        return XFile(url);
      }
    } catch (e) {
      debugPrint('Error creating XFile from URL: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    final state = ref.watch(chatInputStateProvider);
    final notifier = ref.read(chatInputStateProvider.notifier);

    final formattedRecordingTime = _formatRecordingTime(state.recordingDurationSeconds);
    final hasTextContent = state.message.trim().isNotEmpty;
    final hasMediaContent = state.selectedImages.isNotEmpty || state.recordedFilePath != null;
    final hasContent = hasTextContent || hasMediaContent;

    return Column(
      children: [
        // Reply/Edit header
        if (widget.replyingTo != null || widget.editingMessage != null)
          ReplyEditHeader(
            replyingTo: widget.replyingTo,
            editingMessage: widget.editingMessage,
            onCancel: () {
              if (widget.replyingTo != null) {
                widget.onCancelReply?.call();
              } else {
                widget.onCancelEdit?.call();
              }
              notifier.resetState();
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
          padding: widget.padding,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            transitionBuilder:
                (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SizeTransition(sizeFactor: animation, child: child),
                ),
            child:
                state.isRecording
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
                      focusNode: _focusNode,
                      showEmojiPicker: state.showEmojiPicker,
                      hasContent: hasContent,
                      enableAudio: widget.enableAudio,
                      enableImages: widget.enableImages,
                      isRecording: state.isRecording,
                      mediaSelector: widget.mediaSelector,
                      cursorColor: widget.cursorColor,
                      onPickImages: () => notifier.pickImages(widget.imageSource),
                      onSendMessage: () => _sendMessage(ref),
                      onToggleEmojiPicker: notifier.toggleEmojiPicker,
                      onStartRecording: notifier.startRecording,
                      onAttachmentPressed: widget.onAttachmentPressed,
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
    final isEditing = widget.editingMessage != null;

    final message = MessageModel(
      id: widget.editingMessage?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: state.message.trim(),
      type:
          state.recordedFilePath != null
              ? MessageType.audio
              : state.selectedImages.isNotEmpty
              ? MessageType.image
              : MessageType.text,
      createdAt: widget.editingMessage?.createdAt ?? DateTime.now(),
      updatedAt: isEditing ? DateTime.now() : null,
      sender: widget.currentUser,
      isMe: true,
      status: isEditing ? widget.editingMessage!.status : MessageStatus.sending,
      audioPath: state.recordedFilePath,
      imageUrl: state.selectedImages.isNotEmpty ? state.selectedImages.first.path : null,
      replyTo: widget.replyingTo,
    );

    widget.onSend(message, isEditing);
    notifier.resetState();

    if (widget.replyingTo != null) {
      widget.onCancelReply?.call();
    } else if (isEditing) {
      widget.onCancelEdit?.call();
    }
  }
}
