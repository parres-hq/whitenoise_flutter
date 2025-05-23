import 'dart:async';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/models/message_model.dart';
import '../../../domain/models/user_model.dart';
import '../../core/themes/colors.dart';
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
  });

  final User currentUser;
  final void Function(MessageModel message) onSend;
  final VoidCallback? onAttachmentPressed;
  final EdgeInsetsGeometry padding;
  final Color? cursorColor;
  final bool enableAudio;
  final bool enableImages;
  final Widget? mediaSelector;
  final ImageSource imageSource;

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
  List<XFile> _selectedImages = [];

  @override
  void dispose() {
    _textController.dispose();
    _recorderController.dispose();
    _playerController.dispose();
    _focusNode.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  bool get _hasTextContent => _textController.text.trim().isNotEmpty;
  bool get _hasMediaContent => _selectedImages.isNotEmpty || _recordedFilePath != null;
  bool get _hasContent => _hasTextContent || _hasMediaContent;

  String get _formattedRecordingTime {
    final minutes = (_recordingDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingDurationSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Future<void> _pickImages() async {
    if (!widget.enableImages) return;

    final result = await _imagePicker.pickImage(source: widget.imageSource, imageQuality: 70);
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

    if (_recorderController.hasPermission || await _recorderController.checkPermission()) {
      await _recorderController.record();
    }
  }

  Future<void> _stopRecording({bool cancel = false}) async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    if (!cancel) {
      // For now, we'll use a placeholder audio path
      _recordedFilePath = "https://commondatastorage.googleapis.com/codeskulptor-assets/Collision8-Bit.ogg";
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
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _textController.text.trim(),
      type:
          _recordedFilePath != null
              ? MessageType.audio
              : _selectedImages.isNotEmpty
              ? MessageType.image
              : MessageType.text,
      createdAt: DateTime.now(),
      sender: widget.currentUser,
      isMe: true,
      status: MessageStatus.sending,
      audioPath: _recordedFilePath,
      imageUrl: _selectedImages.isNotEmpty ? _selectedImages.first.path : null,
    );

    widget.onSend(message);

    // Reset input state
    _textController.clear();
    setState(() {
      _selectedImages.clear();
      _recordedFilePath = null;
      // _isPlaying = false;
      _showEmojiPicker = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
            transitionBuilder:
                (child, animation) =>
                    FadeTransition(opacity: animation, child: SizeTransition(sizeFactor: animation, child: child)),
            child: _isRecording ? _buildRecordingUI() : _buildTextInputUI(),
          ),
        ),

        // Emoji picker
        if (_showEmojiPicker) _buildEmojiPicker(),
      ],
    );
  }

  Widget _buildAudioPlayer() {
    // If we don't have a recorded file path, return empty container
    if (_recordedFilePath == null) return const SizedBox.shrink();

    return Consumer(
      builder: (context, ref, child) {
        final state = ref.watch(chatAudioProvider(_recordedFilePath!));
        final notifier = ref.read(chatAudioProvider(_recordedFilePath!).notifier);
        final currentlyPlaying = ref.watch(currentlyPlayingAudioProvider);

        final isThisPlaying = currentlyPlaying == _recordedFilePath && state.isPlaying;

        // Handle loading and error states
        if (!state.isReady) {
          if (state.error != null) {
            return SizedBox(
              height: 50.h,
              child: Center(child: Text(state.error!, style: TextStyle(color: Colors.red, fontSize: 12.sp))),
            );
          }
          return SizedBox(
            height: 50.h,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.glitch50)),
          );
        }

        return Container(
          margin: EdgeInsets.symmetric(vertical: 4.h, horizontal: 8.w),
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          color: AppColors.glitch200,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Play/Pause button
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.glitch600),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    isThisPlaying ? CarbonIcons.pause_filled : CarbonIcons.play_filled_alt,
                    color: AppColors.glitch50,
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
                    enableSeekGesture: true,
                    playerWaveStyle: PlayerWaveStyle(
                      fixedWaveColor: AppColors.glitch400,
                      liveWaveColor: AppColors.glitch50,
                      spacing: 6.w,
                      scaleFactor: 0.8,
                      showSeekLine: true,
                      seekLineColor: AppColors.glitch500,
                    ),
                  ),
                ),
              ),

              // Delete button
              IconButton(
                icon: Icon(CarbonIcons.close, size: 20.w, color: AppColors.glitch500),
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
            color: AppColors.glitch80,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Row(
              children: [
                SizedBox(width: 8.w),
                Icon(CarbonIcons.microphone_filled, color: Colors.red, size: 18.w),
                SizedBox(width: 2.w),
                Text(
                  _formattedRecordingTime,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: AppColors.glitch900),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.only(right: 64.w),
                      child: Text(
                        "<   Slide to cancel   <",
                        style: TextStyle(fontSize: 12.sp, color: AppColors.glitch500),
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
              decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: Icon(CarbonIcons.microphone_filled, color: Colors.white, size: 20.w),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputUI() {
    return Container(
      child: Row(
        children: [
          // Attachment button
          if (widget.mediaSelector != null || widget.enableImages)
            widget.mediaSelector ??
                IconButton(
                  padding: EdgeInsets.all(1.sp),
                  icon: Icon(CarbonIcons.add, size: 28.w, color: AppColors.glitch500),
                  onPressed: widget.onAttachmentPressed ?? _pickImages,
                  splashRadius: 0.1,
                ),

          // Text field
          Expanded(
            child: Container(
              decoration: BoxDecoration(color: AppColors.glitch80),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                onChanged: (_) => setState(() {}),
                onTap: () => setState(() => _showEmojiPicker = false),
                cursorColor: widget.cursorColor ?? AppColors.glitch500,
                minLines: 1,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(fontSize: 14.sp, color: AppColors.glitch500),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.w),
                ),
                style: TextStyle(fontSize: 14.sp, color: AppColors.glitch700),
              ),
            ),
          ),

          // Action buttons
          if (_hasContent)
            IconButton(icon: Icon(CarbonIcons.send, size: 24.w, color: AppColors.glitch500), onPressed: _sendMessage)
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji picker toggle
                IconButton(
                  icon: Icon(
                    _showEmojiPicker ? CarbonIcons.text_scale : CarbonIcons.flash,
                    size: 24.w,
                    color: AppColors.glitch500,
                  ),
                  onPressed: _toggleEmojiPicker,
                  padding: EdgeInsets.zero,
                ),

                // Camera button (if enabled)
                if (widget.enableImages)
                  IconButton(
                    icon: Icon(CarbonIcons.camera, size: 24.w, color: AppColors.glitch500),
                    onPressed: _pickImages,
                    padding: EdgeInsets.zero,
                  ),

                // Microphone button (if enabled)
                if (widget.enableAudio)
                  IconButton(
                    icon: Icon(
                      CarbonIcons.microphone,
                      size: 24.w,
                      color: _isRecording ? Theme.of(context).colorScheme.error : AppColors.glitch500,
                    ),
                    onPressed: _startRecording,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      child: EmojiPicker(
        textEditingController: _textController,
        onEmojiSelected: (_, __) => setState(() {}),
        config: Config(
          height: 256,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax: 28 * (defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
          ),
          viewOrderConfig: const ViewOrderConfig(
            top: EmojiPickerItem.categoryBar,
            middle: EmojiPickerItem.emojiView,
            bottom: EmojiPickerItem.searchBar,
          ),
          bottomActionBarConfig: BottomActionBarConfig(enabled: false),
        ),
      ),
    );
  }
}
