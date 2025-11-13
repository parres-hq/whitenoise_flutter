import 'package:flutter_test/flutter_test.dart';
import 'package:whitenoise/domain/models/message_model.dart';
import 'package:whitenoise/domain/models/user_model.dart';
import 'package:whitenoise/domain/services/message_merger_service.dart';

void main() {
  group('MessageMergerService', () {
    group('merge', () {
      group('when state has no sending messages', () {
        final stateMessages = [
          _createMessage(id: 'A'), // sent
          _createMessage(id: 'B', status: MessageStatus.delivered),
          _createMessage(id: 'C', status: MessageStatus.read),
          _createMessage(id: 'D', status: MessageStatus.failed),
        ];
        final dbMessages = [
          _createMessage(id: 'E'),
          _createMessage(id: 'F'),
        ];

        test('only keeps db messages', () {
          final result = MessageMergerService.merge(
            stateMessages: stateMessages,
            dbMessages: dbMessages,
          );

          expect(result, hasLength(2));
          expect(result.map((m) => m.id), equals(['E', 'F']));
        });
      });

      group('when state has recent sending messages', () {
        final recentTime = DateTime.now().subtract(const Duration(seconds: 30));
        final stateMessages = [
          _createMessage(id: 'A'), // sent
          _createMessage(id: 'B', status: MessageStatus.delivered),
          _createMessage(id: 'C', status: MessageStatus.read),
          _createMessage(id: 'D', status: MessageStatus.failed),
          _createMessage(
            id: 'E',
            content: 'I am E and I am in state',
            status: MessageStatus.sending,
            createdAt: recentTime,
          ),
          _createMessage(
            id: 'F',
            content: 'I am F and I am in state',
            status: MessageStatus.sending,
            createdAt: recentTime,
          ),
        ];

        group('when db does not have the sending messages', () {
          final dbMessages = [
            _createMessage(id: 'G', content: 'I am G and I am in db'),
            _createMessage(id: 'H', content: 'I am H and I am in db'),
          ];

          test('keeps recent sending messages from state', () {
            final result = MessageMergerService.merge(
              stateMessages: stateMessages,
              dbMessages: dbMessages,
            );

            expect(result, hasLength(4));
            expect(
              result.map((m) => m.id),
              equals(['G', 'H', 'E', 'F']),
            );
            expect(
              result.map((m) => m.content),
              equals([
                'I am G and I am in db',
                'I am H and I am in db',
                'I am E and I am in state',
                'I am F and I am in state',
              ]),
            );
          });
        });

        group('when db has some sending messages', () {
          final dbMessages = [
            _createMessage(
              id: 'E',
              content: 'I am E and I am in db',
              status: MessageStatus.sending,
              createdAt: recentTime,
            ),
            _createMessage(id: 'G', content: 'I am G and I am in db'),
            _createMessage(id: 'H', content: 'I am H and I am in db'),
          ];

          test('keeps db messages and recent sending messages from state', () {
            final result = MessageMergerService.merge(
              stateMessages: stateMessages,
              dbMessages: dbMessages,
            );

            expect(result, hasLength(4));
            expect(result.map((m) => m.id), equals(['E', 'G', 'H', 'F']));
          });

          test('uses db version when message exists in both db and state', () {
            final result = MessageMergerService.merge(
              stateMessages: stateMessages,
              dbMessages: dbMessages,
            );
            expect(
              result.map((m) => m.content),
              equals([
                'I am E and I am in db',
                'I am G and I am in db',
                'I am H and I am in db',
                'I am F and I am in state',
              ]),
            );
          });
        });
      });

      group('when state has old sending messages', () {
        final oldTime = DateTime.now().subtract(const Duration(minutes: 3));
        final stateMessages = [
          _createMessage(id: 'A'), // sent
          _createMessage(id: 'B', status: MessageStatus.delivered),
          _createMessage(id: 'C', status: MessageStatus.read),
          _createMessage(id: 'D', status: MessageStatus.failed),
          _createMessage(
            id: 'E',
            content: 'I am E and I am in state',
            status: MessageStatus.sending,
            createdAt: oldTime,
          ),
          _createMessage(
            id: 'F',
            content: 'I am F and I am in state',
            status: MessageStatus.sending,
            createdAt: oldTime,
          ),
        ];

        group('when db does not have the old sending messages', () {
          final dbMessages = [
            _createMessage(id: 'G', content: 'I am G and I am in db'),
            _createMessage(id: 'H', content: 'I am H and I am in db'),
          ];

          test('marks old sending messages from state as failed', () {
            final result = MessageMergerService.merge(
              stateMessages: stateMessages,
              dbMessages: dbMessages,
            );

            expect(result, hasLength(4));
            expect(result.map((m) => m.id), equals(['G', 'H', 'E', 'F']));
            expect(
              result.map((m) => m.content),
              equals([
                'I am G and I am in db',
                'I am H and I am in db',
                'I am E and I am in state',
                'I am F and I am in state',
              ]),
            );
            expect(
              result.map((m) => m.status),
              equals([
                MessageStatus.sent,
                MessageStatus.sent,
                MessageStatus.failed,
                MessageStatus.failed,
              ]),
            );
          });
        });

        group('when db has the old sending messages', () {
          final dbMessages = [
            _createMessage(
              id: 'E',
              content: 'I am E and I am in db',
              createdAt: oldTime,
              status: MessageStatus.sending,
            ),
            _createMessage(
              id: 'F',
              content: 'I am F and I am in db',
              createdAt: oldTime,
              status: MessageStatus.sending,
            ),
            _createMessage(id: 'G', content: 'I am G and I am in db'),
            _createMessage(id: 'H', content: 'I am H and I am in db'),
          ];

          test('keeps db messages', () {
            final result = MessageMergerService.merge(
              stateMessages: stateMessages,
              dbMessages: dbMessages,
            );

            expect(result, hasLength(4));
            expect(result.map((m) => m.id), equals(['E', 'F', 'G', 'H']));
            expect(
              result.map((m) => m.content),
              equals([
                'I am E and I am in db',
                'I am F and I am in db',
                'I am G and I am in db',
                'I am H and I am in db',
              ]),
            );
            expect(
              result.map((m) => m.status),
              equals([
                MessageStatus.sending,
                MessageStatus.sending,
                MessageStatus.sent,
                MessageStatus.sent,
              ]),
            );
          });
        });
      });
    });
  });
}

MessageModel _createMessage({
  required String id,
  String content = 'test content',
  MessageStatus status = MessageStatus.sent,
  DateTime? createdAt,
}) {
  return MessageModel(
    id: id,
    content: content,
    type: MessageType.text,
    status: status,
    createdAt: createdAt ?? DateTime.now(),
    sender: User(
      id: 'test_id',
      publicKey: 'test_pubkey',
      displayName: 'Test User',
      nip05: '',
    ),
    isMe: false,
    reactions: [],
  );
}
