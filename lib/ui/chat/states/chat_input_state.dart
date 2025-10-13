import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_input_state.freezed.dart';

@freezed
class ChatInputState with _$ChatInputState {
  const factory ChatInputState({
    @Default(false) bool isLoadingDraft,
    @Default(false) bool showMediaSelector,
    @Default([]) List<String> selectedImages,
    double? singleLineHeight,
    String? previousEditingMessageContent,
  }) = _ChatInputState;
}
