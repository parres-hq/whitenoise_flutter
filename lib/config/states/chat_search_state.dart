import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_search_state.freezed.dart';

@freezed
class ChatSearchState with _$ChatSearchState {
  const factory ChatSearchState({
    @Default('') String query,
    @Default(false) bool isSearchActive,
    @Default([]) List<SearchMatch> matches,
    @Default(0) int currentMatchIndex,
    @Default(false) bool isLoading,
  }) = _ChatSearchState;
}

@freezed
class SearchMatch with _$SearchMatch {
  const factory SearchMatch({
    required String messageId,
    required int messageIndex,
    required String messageContent,
    required List<TextMatch> textMatches,
  }) = _SearchMatch;
}

@freezed
class TextMatch with _$TextMatch {
  const factory TextMatch({
    required int start,
    required int end,
    required String matchedText,
  }) = _TextMatch;
}
