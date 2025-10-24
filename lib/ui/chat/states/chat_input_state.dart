import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:whitenoise/domain/models/media_file_upload.dart';

part 'chat_input_state.freezed.dart';

@freezed
class ChatInputState with _$ChatInputState {
  const factory ChatInputState({
    @Default(false) bool isLoadingDraft,
    @Default(false) bool showMediaSelector,
    @Default([]) List<MediaFileUpload> selectedMedia,
    double? singleLineHeight,
    String? previousEditingMessageContent,
  }) = _ChatInputState;
}
