import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final chatInputStateProvider = StateNotifierProvider<ChatInputNotifier, ChatInputState>((ref) {
  return ChatInputNotifier();
});

class ChatInputState {
  final String message;
  final List<XFile> selectedImages;
  final String? recordedFilePath;
  final bool showEmojiPicker;
  final bool isRecording;
  final int recordingDurationSeconds;
  final double dragOffsetX;
  final bool isDragging;
  final RecorderController? recorderController;

  ChatInputState({
    this.message = '',
    this.selectedImages = const [],
    this.recordedFilePath,
    this.showEmojiPicker = false,
    this.isRecording = false,
    this.recordingDurationSeconds = 0,
    this.dragOffsetX = 0,
    this.isDragging = false,
    this.recorderController,
  });

  ChatInputState copyWith({
    String? message,
    List<XFile>? selectedImages,
    String? recordedFilePath,
    bool? showEmojiPicker,
    bool? isRecording,
    int? recordingDurationSeconds,
    double? dragOffsetX,
    bool? isDragging,
    RecorderController? recorderController,
  }) {
    return ChatInputState(
      message: message ?? this.message,
      selectedImages: selectedImages ?? this.selectedImages,
      recordedFilePath: recordedFilePath ?? this.recordedFilePath,
      showEmojiPicker: showEmojiPicker ?? this.showEmojiPicker,
      isRecording: isRecording ?? this.isRecording,
      recordingDurationSeconds: recordingDurationSeconds ?? this.recordingDurationSeconds,
      dragOffsetX: dragOffsetX ?? this.dragOffsetX,
      isDragging: isDragging ?? this.isDragging,
      recorderController: recorderController ?? this.recorderController,
    );
  }
}

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  ChatInputNotifier() : super(ChatInputState()) {
    // Initialize recorder controller
    state = state.copyWith(
      recorderController:
          RecorderController()
            ..androidEncoder = AndroidEncoder.aac
            ..androidOutputFormat = AndroidOutputFormat.mpeg4
            ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
            ..sampleRate = 44100,
    );
  }

  @override
  void dispose() {
    state.recorderController?.dispose();
    super.dispose();
  }

  void updateMessage(String message) {
    state = state.copyWith(message: message);
  }

  void toggleEmojiPicker() {
    state = state.copyWith(showEmojiPicker: !state.showEmojiPicker);
  }

  Future<void> pickImages(ImageSource source) async {
    final result = await ImagePicker().pickImage(source: source, imageQuality: 70);
    if (result != null) {
      state = state.copyWith(selectedImages: [...state.selectedImages, result]);
    }
  }

  void clearSelectedImages() {
    state = state.copyWith(selectedImages: []);
  }

  Future<void> startRecording() async {
    try {
      await state.recorderController?.record();
      state = state.copyWith(
        isRecording: true,
        recordingDurationSeconds: 0,
        recordedFilePath: null,
      );
      
      // Start timer for recording duration
      _startRecordingTimer();
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  void _startRecordingTimer() {
    // Update recording time every second
    Future.delayed(const Duration(seconds: 1), () {
      if (state.isRecording) {
        state = state.copyWith(
          recordingDurationSeconds: state.recordingDurationSeconds + 1,
        );
        _startRecordingTimer();
      }
    });
  }

  Future<void> stopRecording({bool cancel = true}) async {
    try {
      if (cancel) {
        debugPrint("cancel");
        await state.recorderController?.stop();
        state = state.copyWith(
          isRecording: false,
          recordedFilePath: null,
          dragOffsetX: 0,
        );
      } else {
        debugPrint("send");
        // final path = await state.recorderController?.stop();
        final path = "https://commondatastorage.googleapis.com/codeskulptor-assets/Collision8-Bit.ogg";
        state = state.copyWith(
          isRecording: false,
          recordedFilePath: path,
          dragOffsetX: 0,
        );
      }
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  void handleDragStart() {
    state = state.copyWith(isDragging: true);
  }

  void handleDragUpdate(double deltaX) {
    double newOffsetX = state.dragOffsetX + deltaX;
    if (newOffsetX > 0) newOffsetX = 0;
    state = state.copyWith(dragOffsetX: newOffsetX);
  }

  void handleDragEnd() {
    if (state.dragOffsetX < -60) {
      stopRecording(cancel: false);
    } else {
      state = state.copyWith(dragOffsetX: 0);
    }
    state = state.copyWith(isDragging: false);
  }

  void clearRecordedAudio() {
    state = state.copyWith(recordedFilePath: null);
  }

  void resetState() {
    state = ChatInputState(
      recorderController:
          RecorderController()
            ..androidEncoder = AndroidEncoder.aac
            ..androidOutputFormat = AndroidOutputFormat.mpeg4
            ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
            ..sampleRate = 44100,
    );
  }
}