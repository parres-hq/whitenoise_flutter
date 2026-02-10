import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/config/providers/chat_search_provider.dart';
import 'package:whitenoise/config/states/chat_search_state.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';

MessageModel _makeMessage({
  required String id,
  required String content,
  String senderPubkey = 'test_pubkey',
}) {
  return MessageModel(
    id: id,
    content: content,
    type: MessageType.text,
    createdAt: DateTime(2025, 1, 1, 12),
    sender: User(
      id: senderPubkey,
      publicKey: senderPubkey,
      displayName: 'Tester',
      nip05: '',
    ),
    isMe: false,
    groupId: 'group-1',
  );
}

void main() {
  group('ChatSearchNotifier', () {
    const groupId = 'group-1';
    late ChatSearchNotifier notifier;
    final inputMessages = [
      _makeMessage(id: 'm1', content: 'Hello Hello'),
      _makeMessage(id: 'm2', content: 'say hello again'),
      _makeMessage(id: 'm3', content: 'Holla world'),
    ];

    setUp(() {
      notifier = ChatSearchNotifier(groupId);
    });

    test('activateSearch sets isSearchActive to true', () {
      notifier.activateSearch();

      expect(notifier.state.isSearchActive, true);
    });

    test('deactivateSearch resets state', () {
      notifier.activateSearch();
      notifier.updateQuery('hello');
      final messages = [
        _makeMessage(id: 'm1', content: 'hello world'),
      ];
      notifier.performSearchWithMessages('hello', messages);

      notifier.deactivateSearch();

      expect(
        notifier.state,
        const ChatSearchState(),
      );
    });

    test('performSearchWithMessages builds one match per occurrence across messages', () {
      final inputMessages = [
        _makeMessage(id: 'm1', content: 'Hello Hello'),
        _makeMessage(id: 'm2', content: 'say hello again'),
        _makeMessage(id: 'm3', content: 'no match here'),
      ];

      notifier.performSearchWithMessages('hello', inputMessages);

      final actualState = notifier.state;
      expect(actualState.matches.isNotEmpty, true);
      expect(actualState.matches.length, 3);
      expect(actualState.currentMatchIndex, 0);
      expect(notifier.currentMatch?.messageId, 'm1');

      final matches = actualState.matches;
      expect(matches.length, 3);
      expect(matches[0].messageId, 'm1');
      expect(matches[1].messageId, 'm1');
      expect(matches[2].messageId, 'm2');

      expect(matches[0].currentTextMatch.matchedText.toLowerCase(), 'hello');
      expect(matches[1].currentTextMatch.matchedText.toLowerCase(), 'hello');
      expect(matches[2].currentTextMatch.matchedText.toLowerCase(), 'hello');
    });

    test('goToNextMatch navigate correctly', () {
      notifier.performSearchWithMessages('hello', inputMessages); // 3 matches
      expect(notifier.state.currentMatchIndex, 0);
      expect(notifier.state.matches[0].currentTextMatch, notifier.state.matches[0].textMatches[0]);

      notifier.goToNextMatch();
      expect(notifier.state.currentMatchIndex, 1);
      expect(notifier.state.matches[1].currentTextMatch, notifier.state.matches[1].textMatches[0]);

      notifier.goToNextMatch();
      expect(notifier.state.currentMatchIndex, 2);
      expect(notifier.state.matches[2].currentTextMatch, notifier.state.matches[2].textMatches[0]);

      notifier.goToNextMatch();
      expect(notifier.state.currentMatchIndex, 2);
    });

    test('goToPreviousMatch navigate correctly', () {
      notifier.performSearchWithMessages('hello', inputMessages);
      // Go to the last match so previous button is activated
      notifier.goToNextMatch();
      notifier.goToNextMatch();
      notifier.goToNextMatch();

      notifier.goToPreviousMatch();
      expect(notifier.state.currentMatchIndex, 1);
      expect(notifier.state.matches[1].currentTextMatch, notifier.state.matches[1].textMatches[0]);

      notifier.goToPreviousMatch();
      expect(notifier.state.currentMatchIndex, 0);
      expect(notifier.state.matches[0].currentTextMatch, notifier.state.matches[0].textMatches[0]);
    });

    test('updateQuery with empty string clears results and loading', () {
      notifier.performSearchWithMessages('hello', [
        _makeMessage(id: 'm1', content: 'hello'),
      ]);
      expect(notifier.state.matches, isNotEmpty);

      notifier.updateQuery('');

      expect(notifier.state.query, '');
      expect(notifier.state.matches, isEmpty);
      expect(notifier.state.currentMatchIndex, 0);
      expect(notifier.state.isLoading, false);
    });
  });
}
