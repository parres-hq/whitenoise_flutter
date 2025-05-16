import 'dart:async';
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/ui/chat/widgets/stacked_images.dart';
import '../../../domain/dummy_data/dummy_messages.dart';
import '../../core/themes/colors.dart';

class ChatInput extends StatefulWidget {
  const ChatInput({
    Key? key,
    this.onSend,
    //required this.user,
    required this.padding,
    this.attachBtnClicked,
    this.canUseAudio = true,
    this.cursorColor,
    this.mediaSelector,
    this.imageSource = ImageSource.gallery,
    //required this.theme,
  }) : super(key: key);

  final void Function(MessageModel message)? onSend;
  final void Function()? attachBtnClicked;
  final EdgeInsetsGeometry padding;
  final Color? cursorColor;
  final bool canUseAudio;
  final Widget? mediaSelector;
  final ImageSource imageSource;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final textController = TextEditingController();
  final recorderController = RecorderController();
  final playerController = PlayerController();
  final focusNode = FocusNode();
  String? recordedFilePath;
  bool isPlaying = false;
  List<XFile> images = [];
  bool showEmoji = false;
  bool isRecording = false;

  bool get hasData =>
      textController.text.trim().isNotEmpty || images.isNotEmpty;

  final imagePicker = ImagePicker();

  @override
  void dispose() {
    recorderController.dispose();
    playerController.dispose();
    textController.dispose();
    focusNode.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _handleSend() {

    MessageModel? message;
    final id = messages.length + 1;
    final timeSent = DateTime.now().millisecondsSinceEpoch;
    // format the time like 10:00 AM or 10:00 PM using package [date_format]
    final time = formatDate(DateTime.fromMillisecondsSinceEpoch(timeSent),
        [hh, ':', nn, ' ', am]);
    if (recordedFilePath != null) {
      message = MessageModel(
        id: id.toString(),
        message: null,
        timeSent: time,
        isMe: true,
        reactions: [],
        messageType: 1,
        audioPath: "https://commondatastorage.googleapis.com/codeskulptor-assets/Collision8-Bit.ogg",
        isReplyMessage: false,
      );
    }else{
      message = MessageModel(
        id: id.toString(),
        timeSent: time,
        isMe: true,
        reactions: [],
        messageType: 0,
        imageUrl:null,
        isReplyMessage: false,
        message: textController.text,
      );
    }
    if(images.isNotEmpty){
      message.imageUrl= "https://civilogs.com/uploads/jobs/513/Site_photo_1_11_15_39.png";
    }

    widget.onSend?.call(message);

    focusNode.unfocus();
    setState(() {
      textController.clear();
      images.clear();
      recordedFilePath = null;
      isPlaying = false;
    });
  }

  Future<void> _handleImagePick() async {
    final result = await imagePicker.pickImage(
        source: widget.imageSource, imageQuality: 50);
    if (result != null) {
      setState(() => images.add(result));
    }
  }



  void _startRecording() async {
    setState(() {
      _recordingDurationInSeconds = 0;
    });

    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDurationInSeconds++;
      });
    });

    if (recorderController.hasPermission ||
        await recorderController.checkPermission()) {
      await recorderController.record(
        androidEncoder: AndroidEncoder.aac,
        androidOutputFormat: AndroidOutputFormat.mpeg4,
        iosEncoder: IosEncoder.kAudioFormatMPEG4AAC,
      );
      setState(() => isRecording = true);
    }
  }

  void _stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    recordedFilePath = await recorderController.stop();
    if (recordedFilePath != null) {
      playerController.preparePlayer(path: recordedFilePath!);
    }
    setState(() => isRecording = false);
  }

  void _toggleEmoji() async {
    if (showEmoji) {
      focusNode.requestFocus();
    } else {
      focusNode.unfocus();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() => showEmoji = !showEmoji);
  }

  deletePickedFiles(){
    setState(() {
      images.clear();
    });
  }

  Timer? _recordingTimer;
  int _recordingDurationInSeconds = 0;

  String get _formattedRecordingTime {
    final minutes = (_recordingDurationInSeconds ~/ 60).toString().padLeft(1, '0');
    final seconds = (_recordingDurationInSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (images.isNotEmpty)
          StackedImages(
            imageUris: images.map((e) => e.path).toList(),
            imageSize: 50,
            overlap: 2,
            deleteImageCallback: deletePickedFiles,
          ),
        if (recordedFilePath != null && !isRecording)
          Row(
            children: [
              IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () async {
                  if (isPlaying) {
                    await playerController.pausePlayer();
                    setState(() => isPlaying = false);
                  } else {
                    await playerController.startPlayer();
                    setState(() => isPlaying = false);
                  }
                  setState(() => isPlaying = !isPlaying);
                },
              ),
              Expanded(
                child: AudioFileWaveforms(
                  size: Size(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height * 0.05,
                  ),
                  playerController: playerController,
                  enableSeekGesture: true,
                  waveformType: WaveformType.fitWidth,
                  playerWaveStyle: PlayerWaveStyle(
                    fixedWaveColor: AppColors.color727772,
                    liveWaveColor: AppColors.colorE2E2E2,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    recordedFilePath = null;
                    isPlaying = false;
                  });
                },
              )
            ],
          ),
        if (isRecording)
          AudioWaveforms(
            enableGesture: false,
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height * 0.05,
            ),
            recorderController: recorderController,
            waveStyle: WaveStyle(
              waveColor: AppColors.color727772,
              extendWaveform: true,
              showMiddleLine: false,
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 10),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                child: child,
              ),
            ),
            child: isRecording
                ? _buildRecordingView()  // we'll extract the voice UI into its own method
                : _buildTextInputView(), // same for text input view
          ),
        ),

        if (showEmoji) _buildEmojiPicker(),
      ],
    );
  }
  double _dragOffsetX = 0;
  bool _isDragging = false;

  Widget _buildRecordingView() {
    return Row(
      key: ValueKey('recording'), // Important for AnimatedSwitcher
      children: [
        Expanded(
          child: Container(
            height: 54,
            child: Stack(
              alignment: AlignmentDirectional.centerStart,
              fit: StackFit.loose,
              children: [
                Container(
                  height: 35,
                  margin: const EdgeInsets.only(right: 40),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.colorE2E2E2,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.mic, size: 20, color: AppColors.red1),
                      const SizedBox(width: 8),
                      Text(
                        _formattedRecordingTime,
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.color202320),
                      ),
                      Expanded(
                        child: Container(
                          alignment: Alignment.center,
                          child: Text(
                            "<   Swipe to Stop   <",
                            style: TextStyle(color: AppColors.color727772),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  child: GestureDetector(
                    onHorizontalDragStart: (_) {
                      setState(() {
                        _isDragging = true;
                      });
                    },
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _dragOffsetX += details.delta.dx;
                        // Prevent dragging to the right
                        if (_dragOffsetX > 0) _dragOffsetX = 0;
                      });
                    },
                    onHorizontalDragEnd: (details) {
                      if (_dragOffsetX < -60) {
                        // Swiped far enough left
                        HapticFeedback.mediumImpact();
                        _dragOffsetX = 0;
                        _isDragging = false;
                        _stopRecording();
                      } else {
                        // Not far enough — reset position
                        setState(() {
                          _dragOffsetX = 0;
                        });
                      }
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: _isDragging ? 0 : 300),
                      transform: Matrix4.translationValues(_dragOffsetX, 0, 0),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.red1,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.mic, size: 30, color: AppColors.white),
                    ),
                  ),
                ),



              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInputView() {
    return Row(
      key: ValueKey('textInput'), // Important for AnimatedSwitcher
      children: [
        widget.mediaSelector != null
            ? InkWell(
          child: widget.mediaSelector,
          onTap: _handleImagePick,
        )
            : _buildIconBtn(Icons.attach_file, _handleImagePick),
        const SizedBox(width: 5),
        _buildTextField(),
        const SizedBox(width: 5),
        (hasData || recordedFilePath != null)
            ? _buildIconBtn(Icons.send, _handleSend)
            : widget.canUseAudio
            ? GestureDetector(
          onTap: _startRecording,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: isRecording
                  ? [
                BoxShadow(
                  color: Colors.red.withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                )
              ]
                  : [],
            ),
            child: Icon(
              Icons.mic,
              size: 30,
              color: AppColors.color202320 ?? AppColors.colorE2E2E2,
            ),
          ),
        )
            : SizedBox.shrink(),
      ],
    );
  }


  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Icon(
        icon,
        size: 25,
        color: AppColors.color202320,
      ),
    );
  }

  Widget _buildTextField() {
    final heightFactor = MediaQuery.of(context).size.height * 0.015;
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color:  AppColors.colorE2E2E2,
          borderRadius: BorderRadius.circular(50),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                focusNode: focusNode,
                onChanged: (_) => setState(() {}),
                onTap: () => setState(() => showEmoji = false),
                cursorColor: widget.cursorColor,
                minLines: 1,
                maxLines: 20,
                decoration: InputDecoration(
                  hintText: "Type message here ...",
                  hintStyle: TextStyle(fontSize: heightFactor),
                  border: InputBorder.none,
                ),
                style: TextStyle(fontSize: heightFactor),
              ),
            ),
            InkWell(
              onTap: _toggleEmoji,
              child: Icon(
                showEmoji ? Icons.text_fields_outlined : Icons.emoji_emotions,
                size: 22,
                color: AppColors.color202320,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      child: EmojiPicker(
        textEditingController: textController,
        onEmojiSelected: (_, __) => setState(() {}),
        config: Config(
          height: 256,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            // Issue: https://github.com/flutter/flutter/issues/28894
            emojiSizeMax:
            28 * (defaultTargetPlatform == TargetPlatform.iOS ? 1.20 : 1.0),
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