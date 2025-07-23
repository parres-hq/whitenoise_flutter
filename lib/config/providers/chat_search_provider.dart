import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whitenoise/config/states/chat_search_state.dart';
import 'package:whitenoise/domain/models/message_model.dart';

final chatSearchProvider =
    StateNotifierProvider.family<ChatSearchNotifier, ChatSearchState, String>(
      (ref, groupId) => ChatSearchNotifier(groupId),
    );

class ChatSearchNotifier extends StateNotifier<ChatSearchState> {
  final String groupId;
  Timer? _debounceTimer;

  ChatSearchNotifier(this.groupId) : super(const ChatSearchState());

  void activateSearch() {
    state = state.copyWith(isSearchActive: true);
  }

  void deactivateSearch() {
    _debounceTimer?.cancel();
    state = const ChatSearchState();
  }

  void updateQuery(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      state = state.copyWith(
        query: query,
        matches: [],
        currentMatchIndex: 0,
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(
      query: query,
      isLoading: true,
    );

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      state = state.copyWith(
        matches: [],
        currentMatchIndex: 0,
        isLoading: false,
      );
      return;
    }

    // This will be called from the chat screen with the actual messages
    state = state.copyWith(isLoading: false);
  }

  void performSearchWithMessages(String query, List<MessageModel> messages) {
    if (query.isEmpty) {
      state = state.copyWith(
        matches: [],
        currentMatchIndex: 0,
        isLoading: false,
      );
      return;
    }

    final allMatches = <SearchMatch>[];
    final queryLower = query.toLowerCase();

    // Process messages in normal order (newest first, as they appear in the list)
    // But we want the topmost (oldest visible) match to be #1
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final content = message.content?.toLowerCase() ?? '';

      if (content.contains(queryLower)) {
        int startIndex = 0;
        var matchIndex = content.indexOf(queryLower, startIndex);

        while (matchIndex != -1) {
          // Create a separate SearchMatch for each individual word occurrence
          allMatches.add(
            SearchMatch(
              messageId: message.id,
              messageIndex: i,
              messageContent: message.content ?? '',
              textMatches: [
                TextMatch(
                  start: matchIndex,
                  end: matchIndex + queryLower.length,
                  matchedText: message.content!.substring(matchIndex, matchIndex + queryLower.length),
                ),
              ],
            ),
          );

          startIndex = matchIndex + queryLower.length;
          matchIndex = content.indexOf(queryLower, startIndex);
        }
      }
    }

    // Keep matches in the order they appear (topmost message = first match)
    state = state.copyWith(
      matches: allMatches,
      currentMatchIndex: allMatches.isNotEmpty ? 0 : 0,
      isLoading: false,
    );
  }

  void goToNextMatch() {
    if (state.matches.isEmpty) return;

    final nextIndex = state.currentMatchIndex + 1;
    if (nextIndex < state.matches.length) {
      state = state.copyWith(currentMatchIndex: nextIndex);
    }
  }

  void goToPreviousMatch() {
    if (state.matches.isEmpty) return;

    final prevIndex = state.currentMatchIndex - 1;
    if (prevIndex >= 0) {
      state = state.copyWith(currentMatchIndex: prevIndex);
    }
  }

  SearchMatch? get currentMatch {
    if (state.matches.isEmpty || state.currentMatchIndex >= state.matches.length) {
      return null;
    }
    return state.matches[state.currentMatchIndex];
  }

  bool get hasMatches => state.matches.isNotEmpty;
  int get totalMatches => state.matches.length; // Now each match is a single word occurrence
  int get currentMatchNumber => state.matches.isEmpty ? 0 : state.currentMatchIndex + 1;
}
