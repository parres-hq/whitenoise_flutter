import 'dart:async';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:supa_carbon_icons/supa_carbon_icons.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/models/message_model.dart';
import '../../../domain/models/user_model.dart';
import '../../core/themes/colors.dart';
import 'stacked_images.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.currentUser,
    required this.onSend,
    this.onAttachmentPressed,
    this.cursorColor,
    this.enableAudio = true,
    this.mediaSelector,
    this.imageSource = ImageSource.gallery,
    this.padding = const EdgeInsets.all(8.0),
  });

  final User currentUser;
  final void Function(MessageModel message) onSend;
  final VoidCallback? onAttachmentPressed;
  final EdgeInsetsGeometry padding;
  final Color? cursorColor;
  final bool enableAudio;
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
  bool _isPlaying = false;
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

  bool get _hasContent =>
      _textController.text.trim().isNotEmpty || _selectedImages.isNotEmpty || _recordedFilePath != null;

  String get _formattedRecordingTime {
    final minutes = (_recordingDurationSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingDurationSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  Future<void> _pickImages() async {
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

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    _recordedFilePath = await _recorderController.stop();
    if (_recordedFilePath != null) {
      await _playerController.preparePlayer(path: _recordedFilePath!);
    }

    setState(() {
      _isRecording = false;
      _dragOffsetX = 0;
    });
  }

  void _togglePlayback() async {
    if (_isPlaying) {
      await _playerController.pausePlayer();
    } else {
      await _playerController.startPlayer();
    }
    setState(() => _isPlaying = !_isPlaying);
  }

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
      _isPlaying = false;
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
            padding: EdgeInsets.only(bottom: 8.h),
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
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? CarbonIcons.pause_filled : CarbonIcons.play_filled,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _togglePlayback,
          ),
          Expanded(
            child: AudioFileWaveforms(
              size: Size(1.sw, 40.h),
              playerController: _playerController,
              waveformType: WaveformType.fitWidth,
              playerWaveStyle: PlayerWaveStyle(
                fixedWaveColor: AppColors.glitch600,
                liveWaveColor: Theme.of(context).colorScheme.primary,
                waveCap: StrokeCap.round,
                spacing: 2.w,
              ),
            ),
          ),
          IconButton(
            icon: Icon(CarbonIcons.close, color: AppColors.glitch500),
            onPressed:
                () => setState(() {
                  _recordedFilePath = null;
                  _isPlaying = false;
                }),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingUI() {
    return GestureDetector(
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
      child: Container(
        height: 54.h,
        padding: EdgeInsets.symmetric(horizontal: 12.w),
        decoration: BoxDecoration(
          color: AppColors.glitch50,
          borderRadius: BorderRadius.circular(27.r),
        ),
        child: Row(
          children: [
            Icon(CarbonIcons.microphone_filled, color: Theme.of(context).colorScheme.error, size: 24.w),
            SizedBox(width: 12.w),
            Text(
              _formattedRecordingTime,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Expanded(
              child: Center(
                child: Text("Swipe left to cancel", style: TextStyle(fontSize: 12.sp, color: AppColors.glitch600)),
              ),
            ),
            AnimatedContainer(
              duration: Duration(milliseconds: _isDragging ? 0 : 100),
              transform: Matrix4.translationValues(_dragOffsetX, 0, 0),
              curve: Curves.easeOut,
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.error, shape: BoxShape.circle),
                child: Icon(CarbonIcons.microphone_filled, color: Colors.white, size: 20.w),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputUI() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.glitch50,
        borderRadius: BorderRadius.circular(27.r),
      ),
      child: Row(
        children: [
          // Attachment button
          widget.mediaSelector != null
              ? InkWell(onTap: widget.onAttachmentPressed ?? _pickImages, child: widget.mediaSelector)
              : IconButton(
                icon: Icon(CarbonIcons.attachment, size: 24.w, color: Theme.of(context).colorScheme.primary),
                onPressed: widget.onAttachmentPressed ?? _pickImages,
              ),

          // Text field
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              onChanged: (_) => setState(() {}),
              onTap: () => setState(() => _showEmojiPicker = false),
              cursorColor: widget.cursorColor ?? Theme.of(context).colorScheme.primary,
              minLines: 1,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: TextStyle(fontSize: 14.sp, color: AppColors.glitch600),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
              ),
              style: TextStyle(fontSize: 14.sp, color: Theme.of(context).colorScheme.primary),
            ),
          ),

          // Emoji or Send button
          if (_hasContent)
            IconButton(
              icon: Icon(CarbonIcons.send_filled, size: 24.w, color: Theme.of(context).colorScheme.primary),
              onPressed: _sendMessage,
            )
          else if (widget.enableAudio)
            GestureDetector(
              onTap: _startRecording,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (_isRecording)
                      BoxShadow(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Icon(
                  CarbonIcons.microphone_filled,
                  size: 24.w,
                  color: _isRecording ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.primary,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _showEmojiPicker ? CarbonIcons.text_scale : CarbonIcons.face_activated_add,
                size: 24.w,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: _toggleEmojiPicker,
            ),
        ],
      ),
    );
  }

  // Widget _buildEmojiPicker() {
  //   return SizedBox(
  //     height: 0.35.sh,
  //     child: EmojiPicker(
  //       textEditingController: _textController,
  //       config: Config(
  //         columns: 7,
  //         emojiSizeMax: 28 * (defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
  //         verticalSpacing: 0,
  //         horizontalSpacing: 0,
  //         initCategory: Category.RECENT,
  //         bgColor: AppColors.glitch50,
  //         indicatorColor:Theme.of(context).colorScheme.primary,
  //         iconColor:  AppColors.glitch600,
  //         iconColorSelected:Theme.of(context).colorScheme.primary,
  //         progressIndicatorColor:Theme.of(context).colorScheme.primary,
  //         backspaceColor:Theme.of(context).colorScheme.primary,
  //         skinToneDialogBgColor: Colors.white,
  //         skinToneIndicatorColor: Colors.grey,
  //         enableSkinTones: true,
  //         showRecentsTab: true,
  //         recentsLimit: 28,
  //         noRecentsText: 'No Recents',
  //         noRecentsStyle: TextStyle(
  //           fontSize: 14.sp,
  //           color:Theme.of(context).colorScheme.primary,
  //         ),
  //         categoryIcons: const CategoryIcons(),
  //         buttonMode: ButtonMode.MATERIAL,
  //       ),
  //     ),
  //   );
  // }

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
            // Issue: https://github.com/flutter/flutter/issues/28894
            emojiSizeMax: 28 * (defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
          ),
          viewOrderConfig: const ViewOrderConfig(
            top: EmojiPickerItem.categoryBar,
            middle: EmojiPickerItem.emojiView,
            bottom: EmojiPickerItem.searchBar,
          ),
          skinToneConfig: const SkinToneConfig(),
          categoryViewConfig: const CategoryViewConfig(),
          bottomActionBarConfig: const BottomActionBarConfig(),
          searchViewConfig: const SearchViewConfig(),
        ),
      ),
    );
  }
}
