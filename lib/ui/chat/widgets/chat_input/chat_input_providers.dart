// chat_input_providers.dart
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

  ChatInputState({
    this.message = '',
    this.selectedImages = const [],
    this.recordedFilePath,
    this.showEmojiPicker = false,
    this.isRecording = false,
    this.recordingDurationSeconds = 0,
    this.dragOffsetX = 0,
    this.isDragging = false,
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
    );
  }
}

class ChatInputNotifier extends StateNotifier<ChatInputState> {
  ChatInputNotifier() : super(ChatInputState());

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

  void startRecording() {
    state = state.copyWith(
      isRecording: true,
      recordingDurationSeconds: 0,
    );
  }

  void updateRecordingTime() {
    state = state.copyWith(recordingDurationSeconds: state.recordingDurationSeconds + 1);
  }

  void stopRecording({bool cancel = false}) {
    state = state.copyWith(
      isRecording: false,
      recordedFilePath: cancel ? null : "https://commondatastorage.googleapis.com/codeskulptor-assets/Collision8-Bit.ogg",
      dragOffsetX: 0,
    );
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
      stopRecording(cancel: true);
    } else {
      state = state.copyWith(dragOffsetX: 0);
    }
    state = state.copyWith(isDragging: false);
  }

  void clearRecordedAudio() {
    state = state.copyWith(recordedFilePath: null);
  }

  void resetState() {
    state = ChatInputState();
  }
}