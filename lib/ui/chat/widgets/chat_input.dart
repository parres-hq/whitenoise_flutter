import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:whitenoise/ui/core/themes/src/extensions.dart';

import '../../../domain/models/message_model.dart';
import '../../../domain/models/user_model.dart';
import '../notifiers/chat_audio_notifier.dart';
import 'stacked_images.dart';

class ChatInput extends StatefulWidget {
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
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final _textController = TextEditingController();
  final _recorderController = RecorderController();
  final _playerController = PlayerController();
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();

  String? _recordedFilePath;
  // bool _isPlaying = false;
  bool _showEmojiPicker = false;
  bool _isRecording = false;
  Timer? _recordingTimer;
  int _recordingDurationSeconds = 0;
  double _dragOffsetX = 0;
  bool _isDragging = false;
  final List<XFile> _selectedImages = [];
  MessageModel? _replyingTo;
  MessageModel? _editingMessage;

  @override
  void initState() {
    super.initState();
    _replyingTo = widget.replyingTo;
    _editingMessage = widget.editingMessage;
    if (_editingMessage != null) {
      _textController.text = _editingMessage!.content ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _recorderController.dispose();
    _playerController.dispose();
    _focusNode.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyingTo != oldWidget.replyingTo) {
      setState(() => _replyingTo = widget.replyingTo);
    }
    if (widget.editingMessage != oldWidget.editingMessage) {
      setState(() {
        _editingMessage = widget.editingMessage;
        if (_editingMessage != null) {
          _textController.text = _editingMessage!.content ?? '';
        } else {
          _textController.clear();
        }
      });
    }
  }

  bool get _hasTextContent => _textController.text.trim().isNotEmpty;
  bool get _hasMediaContent =>
      _selectedImages.isNotEmpty || _recordedFilePath != null;
  bool get _hasContent => _hasTextContent || _hasMediaContent;

  String get _formattedRecordingTime {
    final minutes = (_recordingDurationSeconds ~/ 60).toString().padLeft(
      2,
      '0',
    );
    final seconds = (_recordingDurationSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _pickImages() async {
    if (!widget.enableImages) return;

    final result = await _imagePicker.pickImage(
      source: widget.imageSource,
      imageQuality: 70,
    );
    if (result != null) {
      setState(() => _selectedImages.add(result));
    }
  }

  void _clearSelectedImages() {
    setState(() => _selectedImages.clear());
  }

  Future<void> _startRecording() async {
    if (!widget.enableAudio) return;

    setState(() {
      _recordingDurationSeconds = 0;
      _isRecording = true;
    });

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingDurationSeconds++);
    });

    if (_recorderController.hasPermission ||
        await _recorderController.checkPermission()) {
      await _recorderController.record();
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    if (!cancel) {
      // For now, we'll use a placeholder audio path
      _recordedFilePath =
          'https://commondatastorage.googleapis.com/codeskulptor-assets/Collision8-Bit.ogg';
      // In a real app, We would use:
      // _recordedFilePath = await _recorderController.stop();
    } else {
      await _recorderController.stop();
    }

    setState(() {
      _isRecording = false;
      _dragOffsetX = 0;
    });
  }

  // void _togglePlayback() async {
  //   if (_isPlaying) {
  //     await _playerController.pausePlayer();
  //   } else {
  //     await _playerController.startPlayer();
  //   }
  //   setState(() => _isPlaying = !_isPlaying);
  // }

  void _toggleEmojiPicker() async {
    if (_showEmojiPicker) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
      await Future.delayed(const Duration(milliseconds: 100));
    }
    setState(() => _showEmojiPicker = !_showEmojiPicker);
  }

  void _sendMessage() {
    final isEditing = _editingMessage != null;

    final message = MessageModel(
      id:
          _editingMessage?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      content: _textController.text.trim(),
      type: _recordedFilePath != null
          ? MessageType.audio
          : _selectedImages.isNotEmpty
          ? MessageType.image
          : MessageType.text,
      createdAt: _editingMessage?.createdAt ?? DateTime.now(),
      updatedAt: _editingMessage != null ? DateTime.now() : null,
      sender: widget.currentUser,
      isMe: true,
      status: MessageStatus.sending,
      audioPath: _recordedFilePath,
      imageUrl: _selectedImages.isNotEmpty ? _selectedImages.first.path : null,
      replyTo: _replyingTo,
    );

    widget.onSend(message, isEditing);

    // Reset input state
    _textController.clear();
    setState(() {
      _selectedImages.clear();
      _recordedFilePath = null;
      _showEmojiPicker = false;
      if (_replyingTo != null) {
        _replyingTo = null;
        widget.onCancelReply?.call();
      }
      if (_editingMessage != null) {
        _editingMessage = null;
        widget.onCancelEdit?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Reply/Edit header
        _buildReplyOrEditHeader(),

        // Selected images preview
        if (_selectedImages.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 4.h),
            child: StackedImages(
              imageUris: _selectedImages.map((e) => e.path).toList(),
              onDelete: _clearSelectedImages,
            ),
          ),

        // Audio player for recorded audio
        if (_recordedFilePath != null && !_isRecording) _buildAudioPlayer(),

        // Main input area
        Padding(
          padding: widget.padding,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 100),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(sizeFactor: animation, child: child),
            ),
            child: _isRecording ? _buildRecordingUI() : _buildTextInputUI(),
          ),
        ),

        // Emoji picker
        if (_showEmojiPicker) _buildEmojiPicker(),
      ],
    );
  }

  Widget _buildReplyOrEditHeader() {
    if (_replyingTo == null && _editingMessage == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.colors.secondary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6.r)),
      ),
      child: Row(
        children: [
          Icon(
            _replyingTo != null ? CarbonIcons.reply : CarbonIcons.edit,
            size: 16.w,
            color: context.colors.mutedForeground,
          ),
          SizedBox(width: 8.w),
          const Gap(6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyingTo != null
                      ? 'Replying to ${_replyingTo!.sender.name}'
                      : 'Editing message',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: context.colors.neutralVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_replyingTo?.type == MessageType.text &&
                    _replyingTo?.content != null)
                  Text(
                    _replyingTo?.content ?? '',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: context.colors.neutralVariant,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_replyingTo != null) {
                  _replyingTo = null;
                  widget.onCancelReply?.call();
                } else {
                  _editingMessage = null;
                  widget.onCancelEdit?.call();
                }
              });
            },
            child: Icon(
              CarbonIcons.close,
              size: 16.w,
              color: context.colors.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    // If we don't have a recorded file path, return empty container
    if (_recordedFilePath == null) return const SizedBox.shrink();

    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(chatAudioProvider(_recordedFilePath!));
        final notifier = ref.read(
          chatAudioProvider(_recordedFilePath!).notifier,
        );
        final currentlyPlaying = ref.watch(currentlyPlayingAudioProvider);

        final isThisPlaying =
            currentlyPlaying == _recordedFilePath && state.isPlaying;

        // Handle loading and error states
        if (!state.isReady) {
          if (state.error != null) {
            return SizedBox(
              height: 50.h,
              child: Center(
                child: Text(
                  state.error!,
                  style: TextStyle(color: Colors.red, fontSize: 12.sp),
                ),
              ),
            );
          }
          return SizedBox(
            height: 50.h,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: context.colors.primaryForeground,
              ),
            ),
          );
        }

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          decoration: BoxDecoration(color: context.colors.baseMuted),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play/Pause button
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.mutedForeground,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    isThisPlaying
                        ? CarbonIcons.pause_filled
                        : CarbonIcons.play_filled_alt,
                    color: context.colors.primaryForeground,
                    size: 14.w,
                  ),
                  onPressed: () => notifier.togglePlayback(),
                ),
              ),
              SizedBox(width: 8.w),

              // Audio waveform
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 12.w),
                  child: AudioFileWaveforms(
                    playerController: state.playerController!,
                    size: Size(MediaQuery.of(context).size.width * 0.4, 20.h),
                    waveformType: WaveformType.fitWidth,
                    playerWaveStyle: PlayerWaveStyle(
                      fixedWaveColor: context.colors.baseMuted,
                      liveWaveColor: context.colors.primaryForeground,
                      spacing: 6.w,
                      scaleFactor: 0.8,
                      seekLineColor: context.colors.mutedForeground,
                    ),
                  ),
                ),
              ),

              // Delete button
              IconButton(
                icon: Icon(
                  CarbonIcons.close,
                  size: 20.w,
                  color: context.colors.mutedForeground,
                ),
                onPressed: () {
                  // Stop playback if this audio is currently playing
                  // if (isThisPlaying) {
                  //   notifier();
                  // }
                  setState(() => _recordedFilePath = null);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordingUI() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(0.w, 16.w, 0.w, 16.w),
          child: Container(
            decoration: BoxDecoration(color: context.colors.baseMuted),
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                SizedBox(width: 8.w),
                Icon(
                  CarbonIcons.microphone_filled,
                  color: Colors.red,
                  size: 18.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  _formattedRecordingTime,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: context.colors.secondaryForeground,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.only(right: 64.w),
                      child: Text(
                        '<   Slide to cancel   <',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: context.colors.mutedForeground,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          right: 0.w,
          top: 0.h,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => setState(() => _isDragging = true),
            onHorizontalDragUpdate: (details) {
              setState(() {
                _dragOffsetX += details.delta.dx;
                if (_dragOffsetX > 0) _dragOffsetX = 0;
              });
            },
            onHorizontalDragEnd: (details) {
              if (_dragOffsetX < -60) {
                HapticFeedback.mediumImpact();
                _stopRecording();
              } else {
                setState(() => _dragOffsetX = 0);
              }
              setState(() => _isDragging = false);
            },
            child: AnimatedContainer(
              duration: Duration(milliseconds: _isDragging ? 0 : 100),
              transform: Matrix4.translationValues(_dragOffsetX, 0, 0),
              curve: Curves.easeOut,
              width: 64.w,
              height: 64.w,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                CarbonIcons.microphone_filled,
                color: Colors.white,
                size: 20.w,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputUI() {
    return Row(
      children: [
        // Attachment button
        if (widget.mediaSelector != null || widget.enableImages)
          widget.mediaSelector ??
              IconButton(
                padding: EdgeInsets.all(1.sp),
                icon: Icon(
                  CarbonIcons.add,
                  size: 28.w,
                  color: context.colors.mutedForeground,
                ),
                onPressed: widget.onAttachmentPressed ?? _pickImages,
                splashRadius: 0.1,
              ),

        // Text field
        Expanded(
          child: Container(
            decoration: BoxDecoration(color: context.colors.baseMuted),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              onChanged: (_) => setState(() {}),
              onTap: () => setState(() => _showEmojiPicker = false),
              cursorColor: widget.cursorColor ?? context.colors.mutedForeground,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(
                  fontSize: 14.sp,
                  color: context.colors.mutedForeground,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12.w,
                  vertical: 8.w,
                ),
              ),
              style: TextStyle(
                fontSize: 14.sp,
                color: context.colors.neutralVariant,
              ),
            ),
          ),
        ),

        // Action buttons
        if (_hasContent)
          IconButton(
            icon: Icon(
              CarbonIcons.send,
              size: 24.w,
              color: context.colors.mutedForeground,
            ),
            onPressed: _sendMessage,
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji picker toggle
              IconButton(
                icon: Icon(
                  _showEmojiPicker ? CarbonIcons.text_scale : CarbonIcons.flash,
                  size: 24.w,
                  color: context.colors.mutedForeground,
                ),
                onPressed: _toggleEmojiPicker,
                padding: EdgeInsets.zero,
              ),

              // Camera button (if enabled)
              if (widget.enableImages)
                IconButton(
                  icon: Icon(
                    CarbonIcons.camera,
                    size: 24.w,
                    color: context.colors.mutedForeground,
                  ),
                  onPressed: _pickImages,
                  padding: EdgeInsets.zero,
                ),

              // Microphone button (if enabled)
              if (widget.enableAudio)
                IconButton(
                  icon: Icon(
                    CarbonIcons.microphone,
                    size: 24.w,
                    color: _isRecording
                        ? context.colorScheme.error
                        : context.colors.mutedForeground,
                  ),
                  onPressed: _startRecording,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      child: EmojiPicker(
        textEditingController: _textController,
        onEmojiSelected: (_, emoji) => setState(() {}),
        config: Config(
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax:
                28 * (defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
          ),
          bottomActionBarConfig: const BottomActionBarConfig(enabled: false),
        ),
      ),
    );
  }
}
